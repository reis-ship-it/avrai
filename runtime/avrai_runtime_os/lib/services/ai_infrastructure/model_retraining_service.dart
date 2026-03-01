// Model Retraining Service for Phase 12: Neural Network Implementation
// Section 3.2.1: Continuous Learning - Backend Integration
// Handles actual model retraining execution and deployment

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:avrai_runtime_os/ml/model_version_registry.dart';
import 'package:avrai_runtime_os/ml/model_version_info.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/model_version_manager.dart';

/// Model Retraining Service
///
/// Handles the actual execution of model retraining:
/// - Triggers Python training scripts
/// - Monitors training progress
/// - Validates trained models
/// - Deploys new models automatically
///
/// Phase 12 Section 3.2.1: Continuous Learning - Backend Integration
class ModelRetrainingService {
  static const String _logName = 'ModelRetrainingService';

  final ModelVersionManager _versionManager;
  final String projectRoot;

  ModelRetrainingService({
    required ModelVersionManager versionManager,
    String? projectRoot,
  })  : _versionManager = versionManager,
        projectRoot = projectRoot ?? _getProjectRoot();

  /// Get project root directory
  static String _getProjectRoot() {
    // In Flutter, we can't easily get project root from Dart
    // This would need to be passed in or determined at runtime
    // For now, assume we're in the project root or use a relative path
    return '.';
  }

  /// Trigger retraining for a model type
  ///
  /// **Parameters:**
  /// - `modelType`: 'calling_score' or 'outcome'
  /// - `dataPath`: Path to training data JSON file
  /// - `outputPath`: Path where ONNX model should be saved
  ///
  /// **Returns:**
  /// Retraining result with success status and model path
  Future<RetrainingResult> triggerRetraining({
    required String modelType,
    required String dataPath,
    String? outputPath,
  }) async {
    // Web platform doesn't support Process.run
    if (kIsWeb) {
      developer.log(
        'Retraining not supported on web platform. Use backend API instead.',
        name: _logName,
      );
      return RetrainingResult(
        success: false,
        error: 'Retraining not supported on web platform',
        modelPath: null,
      );
    }

    try {
      developer.log(
        'Triggering retraining for $modelType with data: $dataPath',
        name: _logName,
      );

      // Determine output path
      final actualOutputPath = outputPath ?? _getDefaultOutputPath(modelType);

      // Determine which training script to use
      final scriptPath = modelType == 'calling_score'
          ? 'scripts/ml/train_calling_score_model.py'
          : 'scripts/ml/train_outcome_prediction_model.py';

      // Build command
      final pythonCmd = await _findPythonCommand();
      final scriptFullPath = path.join(projectRoot, scriptPath);
      final dataFullPath = path.join(projectRoot, dataPath);
      final outputFullPath = path.join(projectRoot, actualOutputPath);

      // Check if files exist
      if (!await File(scriptFullPath).exists()) {
        throw Exception('Training script not found: $scriptFullPath');
      }

      if (!await File(dataFullPath).exists()) {
        throw Exception('Training data not found: $dataFullPath');
      }

      // Execute training script
      developer.log(
        'Executing: $pythonCmd $scriptFullPath --data-path $dataFullPath --output-path $outputFullPath',
        name: _logName,
      );

      final result = await Process.run(
        pythonCmd,
        [
          scriptFullPath,
          '--data-path',
          dataFullPath,
          '--output-path',
          outputFullPath,
        ],
        workingDirectory: projectRoot,
        runInShell: true,
      );

      if (result.exitCode != 0) {
        developer.log(
          'Training failed: ${result.stderr}',
          name: _logName,
        );
        return RetrainingResult(
          success: false,
          error: result.stderr.toString(),
          modelPath: null,
        );
      }

      // Verify model was created
      if (!await File(outputFullPath).exists()) {
        throw Exception('Model file not created: $outputFullPath');
      }

      // Parse training metrics from output
      final metrics = _parseTrainingMetrics(result.stdout.toString());

      developer.log(
        '✅ Retraining complete: $actualOutputPath',
        name: _logName,
      );

      return RetrainingResult(
        success: true,
        modelPath: actualOutputPath,
        trainingMetrics: metrics,
        stdout: result.stdout.toString(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error triggering retraining: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return RetrainingResult(
        success: false,
        error: e.toString(),
        modelPath: null,
      );
    }
  }

  /// Find Python command (python3 or python)
  Future<String> _findPythonCommand() async {
    // Try python3 first
    try {
      final result = await Process.run('python3', ['--version']);
      if (result.exitCode == 0) {
        return 'python3';
      }
    } catch (e) {
      // python3 not found, try python
    }

    // Try python
    try {
      final result = await Process.run('python', ['--version']);
      if (result.exitCode == 0) {
        return 'python';
      }
    } catch (e) {
      throw Exception('Python not found. Please install Python 3.7+');
    }

    throw Exception('Python not found. Please install Python 3.7+');
  }

  /// Get default output path for a model type
  String _getDefaultOutputPath(String modelType) {
    final timestamp =
        DateTime.now().toIso8601String().split('T').first.replaceAll('-', '');
    if (modelType == 'calling_score') {
      return 'assets/models/calling_score_model_retrained_$timestamp.onnx';
    } else {
      return 'assets/models/outcome_prediction_model_retrained_$timestamp.onnx';
    }
  }

  /// Parse training metrics from script output
  Map<String, dynamic> _parseTrainingMetrics(String output) {
    final metrics = <String, dynamic>{};

    // Parse test loss
    final testLossMatch = RegExp(r'Test Loss:\s*([\d.]+)').firstMatch(output);
    if (testLossMatch != null) {
      metrics['test_loss'] =
          double.tryParse(testLossMatch.group(1) ?? '0') ?? 0.0;
    }

    // Parse validation loss
    final valLossMatch = RegExp(r'Val Loss:\s*([\d.]+)').firstMatch(output);
    if (valLossMatch != null) {
      metrics['val_loss'] =
          double.tryParse(valLossMatch.group(1) ?? '0') ?? 0.0;
    }

    // Parse training loss
    final trainLossMatch = RegExp(r'Train Loss:\s*([\d.]+)').firstMatch(output);
    if (trainLossMatch != null) {
      metrics['train_loss'] =
          double.tryParse(trainLossMatch.group(1) ?? '0') ?? 0.0;
    }

    // Parse early stopping epoch
    final earlyStopMatch =
        RegExp(r'Early stopping at epoch\s*(\d+)').firstMatch(output);
    if (earlyStopMatch != null) {
      metrics['early_stopping_epoch'] =
          int.tryParse(earlyStopMatch.group(1) ?? '0') ?? 0;
    }

    // Parse model parameters
    final paramsMatch = RegExp(r'(\d+)\s*parameters').firstMatch(output);
    if (paramsMatch != null) {
      metrics['parameters'] = int.tryParse(paramsMatch.group(1) ?? '0') ?? 0;
    }

    return metrics;
  }

  /// Validate a trained model
  ///
  /// Checks if model file exists and is valid
  Future<bool> validateModel(String modelPath) async {
    try {
      final fullPath = path.join(projectRoot, modelPath);
      final file = File(fullPath);

      if (!await file.exists()) {
        developer.log('Model file does not exist: $fullPath', name: _logName);
        return false;
      }

      // Check file size (should be > 0)
      final size = await file.length();
      if (size == 0) {
        developer.log('Model file is empty: $fullPath', name: _logName);
        return false;
      }

      // Check file extension
      if (!modelPath.endsWith('.onnx')) {
        developer.log('Model file is not ONNX format: $fullPath',
            name: _logName);
        return false;
      }

      developer.log(
          '✅ Model validated: $modelPath (${(size / 1024).toStringAsFixed(1)} KB)',
          name: _logName);
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error validating model: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Deploy a trained model automatically
  ///
  /// **Parameters:**
  /// - `modelPath`: Path to trained model file
  /// - `modelType`: 'calling_score' or 'outcome'
  /// - `trainingMetrics`: Training performance metrics
  /// - `autoVersion`: If true, auto-generates version number (v1.2, v1.3, etc.)
  ///
  /// **Returns:**
  /// Registered version identifier
  Future<String?> deployModel({
    required String modelPath,
    required String modelType,
    required Map<String, dynamic> trainingMetrics,
    bool autoVersion = true,
  }) async {
    try {
      // Validate model first
      final isValid = await validateModel(modelPath);
      if (!isValid) {
        throw Exception('Model validation failed: $modelPath');
      }

      // Generate version number
      String version;
      if (autoVersion) {
        version = _generateNextVersion(modelType);
      } else {
        // Extract version from model path or use timestamp
        version = _extractVersionFromPath(modelPath) ??
            'v${DateTime.now().millisecondsSinceEpoch}';
      }

      // Get current active version for comparison
      final currentVersion = modelType == 'calling_score'
          ? ModelVersionRegistry.activeCallingScoreVersion
          : ModelVersionRegistry.activeOutcomeVersion;

      // Create version info
      final versionInfo = ModelVersionInfo(
        version: version,
        modelPath: modelPath,
        defaultWeight: 0.1, // Start with low weight
        dataSource: 'real_data', // Retrained models use real data
        trainedDate: DateTime.now(),
        status: ModelStatus.staging,
        description: 'Auto-retrained model (online learning)',
        trainingMetrics: {
          ...trainingMetrics,
          'retraining_date': DateTime.now().toIso8601String(),
          'previous_version': currentVersion,
        },
      );

      // Register version
      await _versionManager.registerVersion(versionInfo, modelType: modelType);

      developer.log(
        '✅ Model deployed: $version ($modelType) at $modelPath',
        name: _logName,
      );

      return version;
    } catch (e, stackTrace) {
      developer.log(
        'Error deploying model: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Generate next version number (v1.2, v1.3, etc.)
  String _generateNextVersion(String modelType) {
    final availableVersions = modelType == 'calling_score'
        ? ModelVersionRegistry.getAvailableCallingScoreVersions()
        : ModelVersionRegistry.getAvailableOutcomeVersions();

    // Find highest version number
    int maxMinor = 0;
    for (final version in availableVersions) {
      final match = RegExp(r'v(\d+)\.(\d+)').firstMatch(version);
      if (match != null) {
        final minor = int.tryParse(match.group(2) ?? '0') ?? 0;
        if (minor > maxMinor) {
          maxMinor = minor;
        }
      }
    }

    // Increment minor version
    return 'v1.${maxMinor + 1}-hybrid'; // Start with hybrid, will be real_data after first retrain
  }

  /// Extract version from model path
  String? _extractVersionFromPath(String modelPath) {
    final match = RegExp(r'v(\d+\.\d+[-\w]*)').firstMatch(modelPath);
    return match?.group(0);
  }

  /// Complete retraining workflow
  ///
  /// Combines retraining, validation, and deployment in one call
  ///
  /// **Parameters:**
  /// - `modelType`: 'calling_score' or 'outcome'
  /// - `dataPath`: Path to training data JSON
  ///
  /// **Returns:**
  /// Deployed version identifier or null if failed
  Future<String?> completeRetrainingWorkflow({
    required String modelType,
    required String dataPath,
  }) async {
    try {
      developer.log(
        'Starting complete retraining workflow for $modelType',
        name: _logName,
      );

      // Step 1: Trigger retraining
      final retrainingResult = await triggerRetraining(
        modelType: modelType,
        dataPath: dataPath,
      );

      if (!retrainingResult.success) {
        developer.log(
          'Retraining failed: ${retrainingResult.error}',
          name: _logName,
        );
        return null;
      }

      // Step 2: Validate model
      final isValid = await validateModel(retrainingResult.modelPath!);
      if (!isValid) {
        developer.log('Model validation failed', name: _logName);
        return null;
      }

      // Step 3: Deploy model
      final version = await deployModel(
        modelPath: retrainingResult.modelPath!,
        modelType: modelType,
        trainingMetrics: retrainingResult.trainingMetrics ?? {},
      );

      if (version == null) {
        developer.log('Model deployment failed', name: _logName);
        return null;
      }

      developer.log(
        '✅ Complete retraining workflow successful: $version',
        name: _logName,
      );

      return version;
    } catch (e, stackTrace) {
      developer.log(
        'Error in complete retraining workflow: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

/// Retraining Result
class RetrainingResult {
  final bool success;
  final String? error;
  final String? modelPath;
  final Map<String, dynamic>? trainingMetrics;
  final String? stdout;

  RetrainingResult({
    required this.success,
    this.error,
    this.modelPath,
    this.trainingMetrics,
    this.stdout,
  });
}
