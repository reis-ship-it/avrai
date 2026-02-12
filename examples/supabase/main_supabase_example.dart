import 'package:flutter/material.dart';
import 'supabase_initializer.dart';
import 'supabase_integration_example.dart';

/// Example main.dart showing how to integrate Supabase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Supabase
    await SupabaseInitializer.initialize();
    // ignore: avoid_print
    print('✅ Supabase initialized successfully');
  } catch (e) {
    // ignore: avoid_print
    print('❌ Failed to initialize Supabase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPOTS - Supabase Integration',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SupabaseIntegrationExample(),
    );
  }
}


