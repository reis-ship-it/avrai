#!/usr/bin/env dart
// ignore_for_file: avoid_print
library;

/// Export training data from Supabase to JSON format
/// Phase 12 Section 2: Neural Network Implementation
///
/// This script exports calling score training data from Supabase
/// to a JSON file that can be used for model training.
///
/// Usage:
///   dart scripts/ml/export_training_data.dart [--output-path OUTPUT_PATH]

import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main(List<String> args) async {
  // Parse arguments
  String outputPath = 'data/calling_score_training_data.json';
  
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--output-path' && i + 1 < args.length) {
      outputPath = args[i + 1];
    }
  }
  
  // Initialize Supabase (you'll need to set these in your environment)
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
  
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print('Error: SUPABASE_URL and SUPABASE_ANON_KEY must be set');
    exit(1);
  }
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  final supabase = Supabase.instance.client;
  
  print('Exporting training data from Supabase...');
  
  try {
    // Fetch all training data
    final response = await supabase
        .from('calling_score_training_data')
        .select()
        .order('created_at', ascending: false);
    
    final records = response as List<dynamic>;
    print('Found ${records.length} training records');
    
    // Convert to training data format
    final trainingData = records.map((record) {
      return {
        'user_vibe_dimensions': record['user_vibe_dimensions'] ?? {},
        'spot_vibe_dimensions': record['spot_vibe_dimensions'] ?? {},
        'context_features': record['context_features'] ?? {},
        'timing_features': record['timing_features'] ?? {},
        'formula_calling_score': record['formula_calling_score'] ?? 0.5,
        'is_called': record['is_called'] ?? false,
        'outcome_type': record['outcome_type'],
        'outcome_score': record['outcome_score'],
      };
    }).toList();
    
    // Create output structure
    final outputData = {
      'metadata': {
        'num_samples': trainingData.length,
        'exported_by': 'export_training_data.dart',
        'description': 'Training data exported from Supabase',
        'exported_at': DateTime.now().toIso8601String(),
      },
      'training_data': trainingData,
    };
    
    // Write to file
    final outputFile = File(outputPath);
    await outputFile.create(recursive: true);
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(outputData),
    );
    
    print('✅ Exported ${trainingData.length} records');
    print('Saved to: $outputPath');
  } catch (e, stackTrace) {
    print('Error exporting data: $e');
    print(stackTrace);
    exit(1);
  }
}
