import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmbeddingCloudClient {
  final SupabaseClient client;
  final String functionName;

  const EmbeddingCloudClient({required this.client, this.functionName = 'embeddings'});

  Future<List<double>> embedOne(String text) async {
    final res = await client.functions.invoke(functionName, body: jsonEncode({
      'texts': [text],
    }));
    if (res.status != 200) {
      throw Exception('Cloud embedding failed: ${res.status} ${res.data}');
    }
    final data = (res.data is String) ? jsonDecode(res.data as String) : res.data;
    final list = (data['embeddings'] as List).first as List;
    return list.map((e) => (e as num).toDouble()).toList();
  }
}


