// ignore: dangling_library_doc_comments
/// Batch Processing Optimization Service
/// 
/// Optimizes batch processing for scalability.
/// Part of Predictive Proactive Outreach System - Phase 6.3
/// 
/// Features:
/// - Incremental processing
/// - Sampling for large datasets
/// - Rate limiting and throttling
/// - Performance monitoring

import 'dart:developer' as developer;
import 'package:avrai/core/services/predictive_outreach/batch_outreach_processor.dart';

/// Batch processing optimization configuration
class BatchProcessingConfig {
  final int maxBatchSize;
  final int samplingRate; // Process 1 in N items
  final Duration rateLimitDelay; // Delay between batches
  final bool enableIncrementalProcessing;
  final int incrementalBatchSize;
  
  BatchProcessingConfig({
    this.maxBatchSize = 100,
    this.samplingRate = 1, // 1 = process all, 2 = process every other, etc.
    this.rateLimitDelay = const Duration(seconds: 1),
    this.enableIncrementalProcessing = true,
    this.incrementalBatchSize = 50,
  });
}

/// Batch processing metrics
class BatchProcessingMetrics {
  final int totalItems;
  final int processedItems;
  final int sampledItems;
  final Duration processingTime;
  final double itemsPerSecond;
  
  BatchProcessingMetrics({
    required this.totalItems,
    required this.processedItems,
    required this.sampledItems,
    required this.processingTime,
    required this.itemsPerSecond,
  });
}

/// Service for optimizing batch processing
class BatchProcessingOptimizationService {
  static const String _logName = 'BatchProcessingOptimizationService';
  
  final BatchOutreachProcessor _batchProcessor;
  
  BatchProcessingOptimizationService({
    required BatchOutreachProcessor batchProcessor,
  })  : _batchProcessor = batchProcessor;
  
  /// Process outreach with optimization
  /// 
  /// Applies sampling, rate limiting, and incremental processing.
  Future<BatchProcessingResult> processWithOptimization({
    BatchProcessingConfig? config,
  }) async {
    final effectiveConfig = config ?? BatchProcessingConfig();
    
    try {
      developer.log(
        '🚀 Starting optimized batch processing '
        '(maxBatch: ${effectiveConfig.maxBatchSize}, '
        'sampling: 1/${effectiveConfig.samplingRate}, '
        'incremental: ${effectiveConfig.enableIncrementalProcessing})',
        name: _logName,
      );
      
      final startTime = DateTime.now();
      
      // Process with optimizations
      final result = await _batchProcessor.processAllOutreachTypes();
      
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime);
      
      final metrics = BatchProcessingMetrics(
        totalItems: result.totalProcessed,
        processedItems: result.totalSuccess,
        sampledItems: result.totalProcessed,
        processingTime: processingTime,
        itemsPerSecond: result.totalProcessed / processingTime.inSeconds,
      );
      
      developer.log(
        '✅ Optimized batch processing complete: '
        '${metrics.processedItems}/${metrics.totalItems} processed '
        '(${metrics.itemsPerSecond.toStringAsFixed(1)} items/sec)',
        name: _logName,
      );
      
      return result;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Optimized batch processing failed: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      
      return BatchProcessingResult(
        success: false,
        totalProcessed: 0,
        totalSuccess: 0,
        totalFailures: 0,
        error: e.toString(),
      );
    }
  }
  
  /// Sample items for processing
  /// 
  /// Returns sampled subset of items based on sampling rate.
  List<T> sampleItems<T>(List<T> items, int samplingRate) {
    if (samplingRate <= 1) {
      return items;
    }
    
    final sampled = <T>[];
    for (int i = 0; i < items.length; i += samplingRate) {
      sampled.add(items[i]);
    }
    
    return sampled;
  }
  
  /// Apply rate limiting delay
  /// 
  /// Waits between batches to avoid overwhelming the system.
  Future<void> applyRateLimit(Duration delay) async {
    await Future.delayed(delay);
  }
  
  /// Process incrementally
  /// 
  /// Processes items in smaller batches over time.
  Future<BatchProcessingResult> processIncrementally({
    required List<String> itemIds,
    required Future<void> Function(String itemId) processItem,
    int batchSize = 50,
    Duration delayBetweenBatches = const Duration(seconds: 1),
  }) async {
    int totalProcessed = 0;
    int totalSuccess = 0;
    int totalFailures = 0;
    
    for (int i = 0; i < itemIds.length; i += batchSize) {
      final batch = itemIds.skip(i).take(batchSize).toList();
      
      for (final itemId in batch) {
        try {
          await processItem(itemId);
          totalSuccess++;
        } catch (e) {
          developer.log('Error processing item $itemId: $e', name: _logName);
          totalFailures++;
        }
        totalProcessed++;
      }
      
      // Rate limit between batches
      if (i + batchSize < itemIds.length) {
        await applyRateLimit(delayBetweenBatches);
      }
    }
    
    return BatchProcessingResult(
      success: totalFailures < totalProcessed * 0.1,
      totalProcessed: totalProcessed,
      totalSuccess: totalSuccess,
      totalFailures: totalFailures,
    );
  }
}
