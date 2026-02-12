import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'dart:developer' as developer;
import 'package:avrai_knot/services/knot/dynamic_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai/core/services/device/wearable_data_service.dart';
import 'package:avrai_knot/models/dynamic_knot.dart';
import 'package:avrai/presentation/widgets/knot/breathing_knot_widget.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

/// Page for knot meditation feature
/// Phase 4: Dynamic Knots (Mood/Energy)
class KnotMeditationPage extends StatefulWidget {
  const KnotMeditationPage({super.key});

  @override
  State<KnotMeditationPage> createState() => _KnotMeditationPageState();
}

class _KnotMeditationPageState extends State<KnotMeditationPage> {
  final _dynamicKnotService = GetIt.instance<DynamicKnotService>();
  final _knotStorageService = GetIt.instance<KnotStorageService>();
  final _wearableDataService = GetIt.instance<WearableDataService>();

  AnimatedKnot? _breathingKnot;
  bool _isMeditating = false;
  double _currentStressLevel = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialStressLevel();
  }

  Future<void> _loadInitialStressLevel() async {
    // Load stress level from wearables, fallback to default
    try {
      final stress = await _wearableDataService.getCurrentStress();
      setState(() {
        _currentStressLevel = stress.value;
      });
    } catch (e) {
      // Fallback to default if wearable data unavailable
      setState(() {
        _currentStressLevel = 0.0;
      });
    }
  }

  Future<void> _startMeditation() async {
    try {
      setState(() {
        _error = null;
        _isMeditating = true;
      });

      // Get user's personality knot
      const agentId = 'current_user'; // In real app, get from auth
      final storedKnot = await _knotStorageService.loadKnot(agentId);

      if (storedKnot == null) {
        // Generate knot if not exists
        developer.log(
          'No stored knot found, generating new knot',
          name: 'KnotMeditationPage',
        );
        // In real app, would need PersonalityProfile
        setState(() {
          _error = 'Please complete onboarding to use meditation feature';
          _isMeditating = false;
        });
        return;
      }

      // Create breathing knot
      final breathingKnot = _dynamicKnotService.createBreathingKnot(
        baseKnot: storedKnot,
        currentStressLevel: _currentStressLevel,
      );

      setState(() {
        _breathingKnot = breathingKnot;
      });

      // Gradually relax knot (simulate stress reduction)
      _graduallyRelaxKnot();
    } catch (e, st) {
      developer.log(
        'Error starting meditation',
        error: e,
        stackTrace: st,
        name: 'KnotMeditationPage',
      );
      setState(() {
        _error = 'Failed to start meditation. Please try again.';
        _isMeditating = false;
      });
    }
  }

  Future<void> _graduallyRelaxKnot() async {
    // Gradually decrease stress level over time
    // Knot breathing slows down, colors transition to calmer tones
    const duration = Duration(minutes: 5);
    const steps = 60;
    final stepDuration = duration ~/ steps;
    final stressReduction = _currentStressLevel / steps;

    for (int i = 0; i < steps; i++) {
      await Future.delayed(stepDuration);

      if (!mounted) return;

      setState(() {
        _currentStressLevel =
            (_currentStressLevel - stressReduction).clamp(0.0, 1.0);

        if (_breathingKnot != null) {
          _breathingKnot = _dynamicKnotService.createBreathingKnot(
            baseKnot: _breathingKnot!.knot,
            currentStressLevel: _currentStressLevel,
          );
        }
      });
    }
  }

  void _stopMeditation() {
    setState(() {
      _isMeditating = false;
      _breathingKnot = null;
      _currentStressLevel = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Knot Meditation',
      constrainBody: false,
      actions: [
        if (_isMeditating)
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: _stopMeditation,
            tooltip: 'Stop Meditation',
          ),
      ],
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _startMeditation,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            : _breathingKnot != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BreathingKnotWidget(
                        animatedKnot: _breathingKnot!,
                        size: 200.0,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Breathe with your knot',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Focus on the rhythm and let stress fade away',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.self_improvement,
                        size: 100,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Knot Meditation',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Use your personality knot to guide your breathing\nand find inner calm',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _isMeditating ? null : _startMeditation,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Meditation'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
