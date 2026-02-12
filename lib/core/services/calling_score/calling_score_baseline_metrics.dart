// Calling Score Baseline Metrics for Phase 12: Neural Network Implementation
// Section 1.2: Baseline Metrics
// Measures current formula-based performance and establishes baseline for comparison

import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calling Score Baseline Metrics
/// 
/// Measures current formula-based calling score performance and establishes
/// baseline metrics for comparison with neural network models.
/// 
/// Phase 12 Section 1.2: Baseline Metrics
/// - Calculates accuracy of current formula-based system
/// - Measures outcome prediction accuracy
/// - Establishes baseline metrics for comparison
/// - Sets success criteria for neural network improvements
class CallingScoreBaselineMetrics {
  static const String _logName = 'CallingScoreBaselineMetrics';
  
  final SupabaseClient _supabase;
  
  // Success criteria (from plan)
  static const double targetCallingScoreImprovement = 0.15; // 15% improvement (10-20% range)
  static const double targetOutcomePredictionImprovement = 0.20; // 20% improvement (15-25% range)
  static const int minimumDataRequirement = 10000; // 10,000 interactions minimum
  
  CallingScoreBaselineMetrics({
    required SupabaseClient supabase,
  }) : _supabase = supabase;
  
  /// Calculate baseline metrics for current formula-based system
  /// 
  /// Returns baseline metrics including:
  /// - Calling score accuracy (how well formula predicts outcomes)
  /// - Outcome prediction accuracy (how well formula predicts positive outcomes)
  /// - False positive rate (called but negative outcome)
  /// - False negative rate (not called but positive outcome)
  /// - Precision, recall, F1 score
  Future<BaselineMetrics> calculateBaselineMetrics() async {
    try {
      developer.log('Calculating baseline metrics for formula-based calling score system', name: _logName);
      
      // Get all training data with outcomes
      final trainingData = await _supabase
          .from('calling_score_training_data')
          .select('*')
          .not('outcome_type', 'is', null);
      
      final records = List<Map<String, dynamic>>.from(trainingData);
      
      if (records.isEmpty) {
        developer.log(
          'No training data with outcomes found. Need ${minimumDataRequirement - records.length} more interactions.',
          name: _logName,
        );
        return BaselineMetrics.empty();
      }
      
      // Calculate metrics
      int truePositives = 0; // Called (score >= 0.70) and positive outcome
      int trueNegatives = 0; // Not called (score < 0.70) and negative/neutral outcome
      int falsePositives = 0; // Called but negative outcome
      int falseNegatives = 0; // Not called but positive outcome
      
      double totalScoreError = 0.0; // Sum of absolute differences between score and outcome
      int scoreErrorCount = 0;
      
      for (final record in records) {
        final formulaScore = (record['formula_calling_score'] as num).toDouble();
        final isCalled = record['formula_is_called'] as bool;
        final outcomeType = record['outcome_type'] as String?;
        final outcomeScore = record['outcome_score'] as num?;
        
        if (outcomeType == null || outcomeScore == null) continue;
        
        final isPositiveOutcome = outcomeType == 'positive';
        final outcomeScoreValue = outcomeScore.toDouble();
        
        // Calculate score error (how far off was the formula score from actual outcome)
        final scoreError = (formulaScore - outcomeScoreValue).abs();
        totalScoreError += scoreError;
        scoreErrorCount++;
        
        // Classify prediction vs outcome
        if (isCalled && isPositiveOutcome) {
          truePositives++;
        } else if (!isCalled && !isPositiveOutcome) {
          trueNegatives++;
        } else if (isCalled && !isPositiveOutcome) {
          falsePositives++;
        } else if (!isCalled && isPositiveOutcome) {
          falseNegatives++;
        }
      }
      
      // Calculate accuracy metrics
      final total = records.length;
      final accuracy = total > 0 ? (truePositives + trueNegatives) / total : 0.0;
      final meanScoreError = scoreErrorCount > 0 ? totalScoreError / scoreErrorCount : 0.0;
      
      // Calculate precision (of all called, how many were positive)
      final precision = (truePositives + falsePositives) > 0
          ? truePositives / (truePositives + falsePositives)
          : 0.0;
      
      // Calculate recall (of all positive outcomes, how many were called)
      final recall = (truePositives + falseNegatives) > 0
          ? truePositives / (truePositives + falseNegatives)
          : 0.0;
      
      // Calculate F1 score (harmonic mean of precision and recall)
      final f1Score = (precision + recall) > 0
          ? 2 * (precision * recall) / (precision + recall)
          : 0.0;
      
      // Calculate outcome prediction accuracy
      // How well does the formula score predict the actual outcome score?
      final outcomePredictionAccuracy = 1.0 - meanScoreError.clamp(0.0, 1.0);
      
      final metrics = BaselineMetrics(
        totalRecords: total,
        truePositives: truePositives,
        trueNegatives: trueNegatives,
        falsePositives: falsePositives,
        falseNegatives: falseNegatives,
        accuracy: accuracy,
        precision: precision,
        recall: recall,
        f1Score: f1Score,
        meanScoreError: meanScoreError,
        outcomePredictionAccuracy: outcomePredictionAccuracy,
        calculatedAt: DateTime.now(),
      );
      
      developer.log(
        '✅ Baseline metrics calculated: accuracy=${(accuracy * 100).toStringAsFixed(1)}%, '
        'precision=${(precision * 100).toStringAsFixed(1)}%, '
        'recall=${(recall * 100).toStringAsFixed(1)}%, '
        'F1=${(f1Score * 100).toStringAsFixed(1)}%, '
        'outcome_prediction=${(outcomePredictionAccuracy * 100).toStringAsFixed(1)}%',
        name: _logName,
      );
      
      return metrics;
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating baseline metrics: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return BaselineMetrics.empty();
    }
  }
  
  /// Check if we have enough data to train neural network models
  /// 
  /// Returns true if we have at least minimumDataRequirement (10,000) interactions
  Future<bool> hasEnoughData() async {
    try {
      final stats = await _getTrainingDataStats();
      return stats['total_records'] as int >= minimumDataRequirement;
    } catch (e) {
      developer.log('Error checking data sufficiency: $e', name: _logName);
      return false;
    }
  }
  
  /// Get data sufficiency status
  /// 
  /// Returns information about current data collection status
  Future<DataSufficiencyStatus> getDataSufficiencyStatus() async {
    try {
      final stats = await _getTrainingDataStats();
      final totalRecords = stats['total_records'] as int;
      final recordsWithOutcomes = stats['records_with_outcomes'] as int;
      final coverageRate = stats['coverage_rate'] as double;
      
      final hasEnough = totalRecords >= minimumDataRequirement;
      final hasEnoughWithOutcomes = recordsWithOutcomes >= (minimumDataRequirement * 0.5); // At least 50% with outcomes
      
      return DataSufficiencyStatus(
        totalRecords: totalRecords,
        recordsWithOutcomes: recordsWithOutcomes,
        coverageRate: coverageRate,
        minimumRequired: minimumDataRequirement,
        hasEnoughData: hasEnough,
        hasEnoughWithOutcomes: hasEnoughWithOutcomes,
        recordsNeeded: (minimumDataRequirement - totalRecords).clamp(0, minimumDataRequirement),
        outcomesNeeded: ((minimumDataRequirement * 0.5).round() - recordsWithOutcomes).clamp(0, minimumDataRequirement),
      );
    } catch (e) {
      developer.log('Error getting data sufficiency status: $e', name: _logName);
      return DataSufficiencyStatus.empty();
    }
  }
  
  /// Get success criteria for neural network improvements
  /// 
  /// Returns target improvements based on baseline metrics
  Future<SuccessCriteria> getSuccessCriteria(BaselineMetrics baseline) async {
    return SuccessCriteria(
      targetCallingScoreAccuracy: (baseline.accuracy + targetCallingScoreImprovement).clamp(0.0, 1.0),
      targetOutcomePredictionAccuracy: (baseline.outcomePredictionAccuracy + targetOutcomePredictionImprovement).clamp(0.0, 1.0),
      targetPrecision: (baseline.precision + targetCallingScoreImprovement).clamp(0.0, 1.0),
      targetRecall: (baseline.recall + targetCallingScoreImprovement).clamp(0.0, 1.0),
      targetF1Score: (baseline.f1Score + targetCallingScoreImprovement).clamp(0.0, 1.0),
      baselineMetrics: baseline,
    );
  }
  
  /// Get training data stats (internal helper)
  Future<Map<String, dynamic>> _getTrainingDataStats() async {
    try {
      // Get all records
      final allRecords = await _supabase
          .from('calling_score_training_data')
          .select('id, outcome_type');
      
      final records = List<Map<String, dynamic>>.from(allRecords);
      final totalRecords = records.length;
      
      // Count records with outcomes
      final recordsWithOutcomesList = records
          .where((r) => r['outcome_type'] != null)
          .toList();
      final recordsWithOutcomes = recordsWithOutcomesList.length;
      
      final coverageRate = totalRecords > 0 ? recordsWithOutcomes / totalRecords : 0.0;
      
      return {
        'total_records': totalRecords,
        'records_with_outcomes': recordsWithOutcomes,
        'coverage_rate': coverageRate,
      };
    } catch (e) {
      developer.log('Error getting training data stats: $e', name: _logName);
      return {
        'total_records': 0,
        'records_with_outcomes': 0,
        'coverage_rate': 0.0,
      };
    }
  }
}

/// Baseline Metrics
/// 
/// Performance metrics for the current formula-based calling score system
class BaselineMetrics {
  final int totalRecords;
  final int truePositives;
  final int trueNegatives;
  final int falsePositives;
  final int falseNegatives;
  final double accuracy; // Overall accuracy (TP + TN) / Total
  final double precision; // TP / (TP + FP) - Of all called, how many were positive
  final double recall; // TP / (TP + FN) - Of all positive, how many were called
  final double f1Score; // Harmonic mean of precision and recall
  final double meanScoreError; // Average absolute difference between score and outcome
  final double outcomePredictionAccuracy; // 1.0 - meanScoreError (clamped)
  final DateTime calculatedAt;
  
  BaselineMetrics({
    required this.totalRecords,
    required this.truePositives,
    required this.trueNegatives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.accuracy,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.meanScoreError,
    required this.outcomePredictionAccuracy,
    required this.calculatedAt,
  });
  
  factory BaselineMetrics.empty() {
    return BaselineMetrics(
      totalRecords: 0,
      truePositives: 0,
      trueNegatives: 0,
      falsePositives: 0,
      falseNegatives: 0,
      accuracy: 0.0,
      precision: 0.0,
      recall: 0.0,
      f1Score: 0.0,
      meanScoreError: 0.0,
      outcomePredictionAccuracy: 0.0,
      calculatedAt: DateTime.now(),
    );
  }
  
  /// Convert to JSON for storage/display
  Map<String, dynamic> toJson() {
    return {
      'total_records': totalRecords,
      'true_positives': truePositives,
      'true_negatives': trueNegatives,
      'false_positives': falsePositives,
      'false_negatives': falseNegatives,
      'accuracy': accuracy,
      'precision': precision,
      'recall': recall,
      'f1_score': f1Score,
      'mean_score_error': meanScoreError,
      'outcome_prediction_accuracy': outcomePredictionAccuracy,
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }
}

/// Success Criteria
/// 
/// Target metrics for neural network improvements
class SuccessCriteria {
  final double targetCallingScoreAccuracy;
  final double targetOutcomePredictionAccuracy;
  final double targetPrecision;
  final double targetRecall;
  final double targetF1Score;
  final BaselineMetrics baselineMetrics;
  
  SuccessCriteria({
    required this.targetCallingScoreAccuracy,
    required this.targetOutcomePredictionAccuracy,
    required this.targetPrecision,
    required this.targetRecall,
    required this.targetF1Score,
    required this.baselineMetrics,
  });
  
  /// Check if neural network model meets success criteria
  bool meetsCriteria(BaselineMetrics modelMetrics) {
    return modelMetrics.accuracy >= targetCallingScoreAccuracy &&
           modelMetrics.outcomePredictionAccuracy >= targetOutcomePredictionAccuracy &&
           modelMetrics.precision >= targetPrecision &&
           modelMetrics.recall >= targetRecall &&
           modelMetrics.f1Score >= targetF1Score;
  }
  
  /// Convert to JSON for storage/display
  Map<String, dynamic> toJson() {
    return {
      'target_calling_score_accuracy': targetCallingScoreAccuracy,
      'target_outcome_prediction_accuracy': targetOutcomePredictionAccuracy,
      'target_precision': targetPrecision,
      'target_recall': targetRecall,
      'target_f1_score': targetF1Score,
      'baseline_metrics': baselineMetrics.toJson(),
    };
  }
}

/// Data Sufficiency Status
/// 
/// Information about whether we have enough data to train neural network models
class DataSufficiencyStatus {
  final int totalRecords;
  final int recordsWithOutcomes;
  final double coverageRate; // Percentage of records with outcomes
  final int minimumRequired;
  final bool hasEnoughData;
  final bool hasEnoughWithOutcomes;
  final int recordsNeeded;
  final int outcomesNeeded;
  
  DataSufficiencyStatus({
    required this.totalRecords,
    required this.recordsWithOutcomes,
    required this.coverageRate,
    required this.minimumRequired,
    required this.hasEnoughData,
    required this.hasEnoughWithOutcomes,
    required this.recordsNeeded,
    required this.outcomesNeeded,
  });
  
  factory DataSufficiencyStatus.empty() {
    return DataSufficiencyStatus(
      totalRecords: 0,
      recordsWithOutcomes: 0,
      coverageRate: 0.0,
      minimumRequired: CallingScoreBaselineMetrics.minimumDataRequirement,
      hasEnoughData: false,
      hasEnoughWithOutcomes: false,
      recordsNeeded: CallingScoreBaselineMetrics.minimumDataRequirement,
      outcomesNeeded: CallingScoreBaselineMetrics.minimumDataRequirement ~/ 2,
    );
  }
  
  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    return (totalRecords / minimumRequired).clamp(0.0, 1.0);
  }
  
  /// Convert to JSON for storage/display
  Map<String, dynamic> toJson() {
    return {
      'total_records': totalRecords,
      'records_with_outcomes': recordsWithOutcomes,
      'coverage_rate': coverageRate,
      'minimum_required': minimumRequired,
      'has_enough_data': hasEnoughData,
      'has_enough_with_outcomes': hasEnoughWithOutcomes,
      'records_needed': recordsNeeded,
      'outcomes_needed': outcomesNeeded,
      'progress_percentage': progressPercentage,
    };
  }
}
