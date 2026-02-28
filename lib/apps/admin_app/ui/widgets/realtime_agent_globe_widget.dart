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
  });

  final List<ActiveAIAgentData> agents;
  final String title;

  @override
  State<RealtimeAgentGlobeWidget> createState() =>
      _RealtimeAgentGlobeWidgetState();
}

class _RealtimeAgentGlobeWidgetState extends State<RealtimeAgentGlobeWidget> {
  ThreeJsBridgeService? _bridge;

  @override
  void didUpdateWidget(covariant RealtimeAgentGlobeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agents != widget.agents) {
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

    await bridge.evaluateJavascript(
      'if(window.globeRenderer){window.globeRenderer.setAgents(${jsonEncode(payload)});}',
    );
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
