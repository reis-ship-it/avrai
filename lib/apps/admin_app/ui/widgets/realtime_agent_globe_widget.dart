import 'dart:convert';

import 'package:avrai/core/services/admin/admin_runtime_governance_service.dart';
import 'package:avrai/core/services/visualization/three_js_bridge_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/visualization/three_js_visualization_widget.dart';
import 'package:flutter/material.dart';

class RealtimeAgentGlobeWidget extends StatefulWidget {
  const RealtimeAgentGlobeWidget({
    super.key,
    required this.agents,
    required this.title,
    this.links = const <GlobeConnectionLink>[],
    this.temporalState,
    this.onTemporalStateRendered,
  });

  final List<ActiveAIAgentData> agents;
  final String title;
  final List<GlobeConnectionLink> links;
  final GlobeTemporalStateView? temporalState;
  final ValueChanged<GlobeTemporalRenderAck>? onTemporalStateRendered;

  @override
  State<RealtimeAgentGlobeWidget> createState() =>
      _RealtimeAgentGlobeWidgetState();
}

class _RealtimeAgentGlobeWidgetState extends State<RealtimeAgentGlobeWidget> {
  ThreeJsBridgeService? _bridge;

  @override
  void didUpdateWidget(covariant RealtimeAgentGlobeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agents != widget.agents ||
        oldWidget.links != widget.links ||
        oldWidget.temporalState != widget.temporalState) {
      _pushAgentsToGlobe();
    }
  }

  Future<void> _pushAgentsToGlobe() async {
    final bridge = _bridge;
    if (bridge == null || !bridge.isReady) {
      return;
    }

    final payload = widget.agents
        .map(
          (agent) => <String, dynamic>{
            'agentId': agent.aiSignature,
            'lat': agent.latitude,
            'lng': agent.longitude,
            'isOnline': agent.isOnline,
            'connections': agent.aiConnections,
            'stage': agent.currentStage,
          },
        )
        .toList();

    final linksPayload = widget.links
        .map(
          (link) => <String, dynamic>{
            'from': link.fromAgentId,
            'to': link.toAgentId,
            'strength': link.strength,
          },
        )
        .toList();

    await bridge.evaluateJavascript(
      'if(window.globeRenderer){window.globeRenderer.setAgents(${jsonEncode(payload)});}',
    );
    await bridge.evaluateJavascript(
      'if(window.globeRenderer){window.globeRenderer.setConnections(${jsonEncode(linksPayload)});}',
    );
    if (widget.temporalState != null) {
      await bridge.evaluateJavascript(
        'if(window.globeRenderer){window.globeRenderer.setTemporalState(${jsonEncode(widget.temporalState!.toJson())});}',
      );
      widget.onTemporalStateRendered?.call(
        GlobeTemporalRenderAck(
          state: widget.temporalState!.currentState,
          progress: widget.temporalState!.progress,
          renderedAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = widget.agents.where((agent) => agent.isOnline).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Real-time 3D globe showing agent identity placement only (no personal data).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.temporalState != null) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: widget.temporalState!.progress,
                minHeight: 5,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.temporalState!.states
                    .map(
                      (state) => Chip(
                        avatar: Icon(
                          state == widget.temporalState!.currentState
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 16,
                        ),
                        label: Text(state),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              width: double.infinity,
              child: ThreeJsVisualizationWidget(
                htmlFile: 'admin_agent_globe.html',
                width: double.infinity,
                height: 360,
                showControls: true,
                onReady: (bridge) {
                  _bridge = bridge;
                  _pushAgentsToGlobe();
                },
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Total agents: ${widget.agents.length}')),
                Chip(label: Text('Online: $onlineCount')),
                Chip(
                    label:
                        Text('Offline: ${widget.agents.length - onlineCount}')),
                Chip(label: Text('Pathways: ${widget.links.length}')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Visible IDs: ${widget.agents.take(5).map((agent) => _safePrefix(agent.aiSignature, 10)).join(', ')}',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _safePrefix(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength);
  }
}

class GlobeConnectionLink {
  const GlobeConnectionLink({
    required this.fromAgentId,
    required this.toAgentId,
    required this.strength,
  });

  final String fromAgentId;
  final String toAgentId;
  final double strength;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlobeConnectionLink &&
        other.fromAgentId == fromAgentId &&
        other.toAgentId == toAgentId &&
        other.strength == strength;
  }

  @override
  int get hashCode => Object.hash(fromAgentId, toAgentId, strength);
}

class GlobeTemporalStateView {
  const GlobeTemporalStateView({
    required this.currentState,
    required this.progress,
    required this.states,
  });

  final String currentState;
  final double progress;
  final List<String> states;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'state': currentState,
      'progress': progress,
      'states': states,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlobeTemporalStateView &&
        other.currentState == currentState &&
        other.progress == progress &&
        _sameList(other.states, states);
  }

  @override
  int get hashCode =>
      Object.hash(currentState, progress, Object.hashAll(states));

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class GlobeTemporalRenderAck {
  const GlobeTemporalRenderAck({
    required this.state,
    required this.progress,
    required this.renderedAt,
  });

  final String state;
  final double progress;
  final DateTime renderedAt;
}
