// Knot Debug Tab
// 
// Admin tab for knot debugging tools
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 9: Admin Knot Visualizer

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/services/admin/knot_admin_service.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Tab for knot debugging tools
class KnotDebugTab extends StatefulWidget {
  const KnotDebugTab({super.key});

  @override
  State<KnotDebugTab> createState() => _KnotDebugTabState();
}

class _KnotDebugTabState extends State<KnotDebugTab> {
  final _knotAdminService = GetIt.instance<KnotAdminService>();
  final _agentIdController = TextEditingController();
  PersonalityKnot? _loadedKnot;
  bool _isValidating = false;
  bool? _isValid;
  String? _validationMessage;
  Map<String, dynamic>? _systemStats;

  @override
  void initState() {
    super.initState();
    _loadSystemStats();
  }

  @override
  void dispose() {
    _agentIdController.dispose();
    super.dispose();
  }

  Future<void> _loadSystemStats() async {
    try {
      final stats = await _knotAdminService.getSystemKnotStatistics();
      setState(() {
        _systemStats = stats;
      });
    } catch (e) {
      developer.log('Error loading system stats: $e', name: 'KnotDebugTab');
    }
  }

  Future<void> _loadKnot() async {
    final agentId = _agentIdController.text.trim();
    if (agentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an agent ID')),
      );
      return;
    }

    try {
      final knot = await _knotAdminService.getUserKnot(agentId);
      if (!mounted) return;
      
      setState(() {
        _loadedKnot = knot;
      });

      if (knot == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Knot not found')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _validateKnot() async {
    if (_loadedKnot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please load a knot first')),
      );
      return;
    }

    setState(() {
      _isValidating = true;
      _isValid = null;
      _validationMessage = null;
    });

    try {
      final isValid = await _knotAdminService.validateKnot(_loadedKnot!);
      setState(() {
        _isValidating = false;
        _isValid = isValid;
        _validationMessage = isValid
            ? 'Knot structure is valid'
            : 'Knot structure is invalid';
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _isValid = false;
        _validationMessage = 'Validation error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // System Statistics
        if (_systemStats != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Statistics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ..._systemStats!.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text('${entry.value}'),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Load Knot
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Load Knot',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _agentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Agent ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadKnot,
                  child: const Text('Load Knot'),
                ),
              ],
            ),
          ),
        ),

        if (_loadedKnot != null) ...[
          const SizedBox(height: 16),

          // Knot Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Knot Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Agent ID: ${_loadedKnot!.agentId}'),
                  Text(
                    'Crossing Number: ${_loadedKnot!.invariants.crossingNumber}',
                  ),
                  Text('Writhe: ${_loadedKnot!.invariants.writhe}'),
                  Text(
                    'Jones Polynomial: ${_loadedKnot!.invariants.jonesPolynomial}',
                  ),
                  Text(
                    'Alexander Polynomial: ${_loadedKnot!.invariants.alexanderPolynomial}',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _validateKnot,
                    child: _isValidating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Validate Knot'),
                  ),
                  if (_isValid != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _validationMessage ?? '',
                      style: TextStyle(
                        color: _isValid! ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
