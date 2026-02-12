class ConfigService {
  final String environment; // development | staging | production
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googlePlacesApiKey;
  final bool debug;
  
  // Inference configuration
  final String inferenceBackend; // onnx | tflite | coreml
  final String orchestrationStrategy; // device_first | edge_prefetch
  
  // Model configuration (for default initialization and demo smoke tests)
  final String modelAssetPath; // e.g., assets/models/default.onnx
  final String modelInputName; // e.g., input
  final String modelOutputName; // e.g., output
  final List<int> modelInputShape; // e.g., [1, 1]
  final String modelDownloadUrl; // optional remote URL to fetch model bytes

  // NLP model configuration (multilingual BERT defaults)
  final int nlpMaxSeqLen; // e.g., 128
  final int nlpHiddenSize; // e.g., 768
  final String nlpInputIdsName; // 'input_ids'
  final String nlpAttentionMaskName; // 'attention_mask'
  final String nlpTokenTypeIdsName; // 'token_type_ids'
  final String nlpOutputName; // 'last_hidden_state' or 'pooled_output'
  final bool nlpDoLowerCase; // false for cased models

  const ConfigService({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.googlePlacesApiKey = '',
    this.debug = false,
    this.inferenceBackend = 'onnx',
    this.orchestrationStrategy = 'device_first',
    this.modelAssetPath = 'assets/models/default.onnx',
    this.modelInputName = 'input',
    this.modelOutputName = 'output',
    this.modelInputShape = const [1],
    this.modelDownloadUrl = '',
    this.nlpMaxSeqLen = 128,
    this.nlpHiddenSize = 768,
    this.nlpInputIdsName = 'input_ids',
    this.nlpAttentionMaskName = 'attention_mask',
    this.nlpTokenTypeIdsName = 'token_type_ids',
    this.nlpOutputName = 'last_hidden_state',
    this.nlpDoLowerCase = false,
  });

  bool get isProd => environment.toLowerCase() == 'production';
  bool get isDev => environment.toLowerCase() == 'development';
}


