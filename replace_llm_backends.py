with open('runtime/avrai_runtime_os/lib/services/ai_infrastructure/llm_service_backends.dart', 'r') as f:
    content = f.read()

# Add responseFormat to LlmBackend.chat
old_signature = """  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
  });"""

new_signature = """  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    String? responseFormat, // Optional JSON schema enforcement
  });"""

content = content.replace(old_signature, new_signature)

# We also need to add responseFormat to CloudGeminiBackend and CloudFailoverBackend, etc.
# Actually, it's easier to just do a regex or replace all "required Duration timeout," with "required Duration timeout, String? responseFormat,"
content = content.replace("required Duration timeout,", "required Duration timeout, String? responseFormat,")

split_str = '/// Local backend that calls into platform implementations.'
parts = content.split(split_str)

new_content = parts[0] + """/// Unified Mobile/Edge backend using MLC-LLM (Machine Learning Compilation).
/// Runs Qwen 2.5 3B / Llama 3.2 1B natively on iOS (Metal) and Android (Vulkan/OpenCL).
class MlcLlmBackend implements LlmBackend {
  static const MethodChannel _channel = MethodChannel('avrai/mlc_llm');
  static const EventChannel _streamChannel = EventChannel('avrai/mlc_llm_stream');

  String? _loadedModelDir;

  Future<void> _ensureLoaded(String modelDir) async {
    if (_loadedModelDir == modelDir) return;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'loadModel',
        <String, dynamic>{'model_dir': modelDir},
      );
      if (ok != true) {
        throw Exception('MLC-LLM loadModel returned false');
      }
      _loadedModelDir = modelDir;
    } on PlatformException catch (e) {
      throw Exception('MLC-LLM loadModel platform error: ${e.code} ${e.message}');
    }
  }

  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    String? responseFormat,
  }) async {
    try {
      final prefs = await SharedPreferencesCompat.getInstance();
      final modelDir = prefs.getString(LLMService._prefsKeyLocalLlmActiveModelDir) ?? '';
      if (modelDir.isEmpty) {
        throw Exception('MLC model not installed (missing model_dir)');
      }
      await _ensureLoaded(modelDir);

      final payload = <String, dynamic>{
        'messages': messages.map((m) => m.toJson()).toList(),
        'temperature': temperature,
        'maxTokens': maxTokens,
        if (responseFormat != null) 'response_format': responseFormat,
      };

      final res = await _channel.invokeMethod<String>('generate', payload).timeout(timeout);

      if (res == null || res.isEmpty) {
        throw Exception('Empty MLC-LLM response');
      }
      return res;
    } on PlatformException catch (e) {
      throw Exception('MLC-LLM platform error: ${e.code} ${e.message}');
    } on TimeoutException {
      throw TimeoutException('MLC-LLM timed out');
    }
  }

  @override
  Stream<String> chatStream({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required bool useRealSse,
    required bool autoFallback,
  }) async* {
    final prefs = await SharedPreferencesCompat.getInstance();
    final modelDir = prefs.getString(LLMService._prefsKeyLocalLlmActiveModelDir) ?? '';
    if (modelDir.isEmpty) {
      throw Exception('MLC model not installed (missing model_dir)');
    }
    await _ensureLoaded(modelDir);

    final payload = <String, dynamic>{
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'maxTokens': maxTokens,
    };

    String acc = '';
    try {
      await _channel.invokeMethod<void>('startStream', payload);
      final stream = _streamChannel.receiveBroadcastStream();
      await for (final event in stream) {
        if (event is Map) {
          final type = event['type'];
          if (type == 'token') {
            final token = event['text'];
            if (token is String && token.isNotEmpty) {
              acc += token;
              yield acc;
            }
          } else if (type == 'done') {
            return;
          } else if (type == 'error') {
            throw Exception(event['message']?.toString() ?? 'MLC stream error');
          }
        }
      }
    } on PlatformException catch (e) {
      throw Exception('MLC stream platform error: ${e.code} ${e.message}');
    }
  }
}

/// Dedicated desktop node backend (macOS, Windows, Linux)
/// Optimized for running larger models like Phi-4 Mini (3.8B) for high-density reasoning
class DesktopPhi4LlmBackend implements LlmBackend {
  // Stub implementation mirroring MLC, can use FFI or desktop channels
  @override
  Future<String> chat({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required Duration timeout,
    String? responseFormat,
  }) async {
    return "Desktop Phi-4 Backend Output (Stub)";
  }

  @override
  Stream<String> chatStream({
    required LLMService service,
    required List<ChatMessage> messages,
    required LLMContext? context,
    required double temperature,
    required int maxTokens,
    required bool useRealSse,
    required bool autoFallback,
  }) async* {
    yield "Desktop Phi-4 Stream Output (Stub)";
  }
}
"""

with open('runtime/avrai_runtime_os/lib/services/ai_infrastructure/llm_service_backends.dart', 'w') as f:
    f.write(new_content)
