import 'package:avrai_core/models/kernel_graph/kernel_graph_models.dart';

typedef KernelGraphPrimitiveExecutor = Future<KernelGraphNodeExecutionResult>
    Function(
  KernelGraphExecutionContext context,
  KernelGraphCompiledStep step,
);

class KernelGraphPrimitiveHandler {
  const KernelGraphPrimitiveHandler({
    required this.id,
    required this.label,
    required this.execute,
    this.description,
  });

  final String id;
  final String label;
  final String? description;
  final KernelGraphPrimitiveExecutor execute;
}

class KernelGraphPrimitiveRegistry {
  final Map<String, KernelGraphPrimitiveHandler> _handlers =
      <String, KernelGraphPrimitiveHandler>{};

  void register(KernelGraphPrimitiveHandler handler) {
    _handlers[handler.id] = handler;
  }

  bool contains(String primitiveId) => _handlers.containsKey(primitiveId);

  KernelGraphPrimitiveHandler? lookup(String primitiveId) {
    return _handlers[primitiveId];
  }

  List<KernelGraphPrimitiveHandler> get handlers =>
      _handlers.values.toList(growable: false);
}

class KernelGraphExecutionContext {
  KernelGraphExecutionContext({
    required this.runId,
    required this.specId,
    Map<String, dynamic> initialState = const <String, dynamic>{},
  }) : _state = Map<String, dynamic>.from(initialState);

  final String runId;
  final String specId;
  final Map<String, dynamic> _state;
  final Map<String, List<String>> _artifactRefsByNode =
      <String, List<String>>{};

  T? read<T>(String key) {
    final value = _state[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  Map<String, dynamic> snapshot() => Map<String, dynamic>.from(_state);

  void write(String key, dynamic value) {
    _state[key] = value;
  }

  void recordArtifact(String nodeId, String artifactRef) {
    _artifactRefsByNode.putIfAbsent(nodeId, () => <String>[]).add(artifactRef);
  }

  List<String> artifactRefsFor(String nodeId) {
    return List<String>.from(_artifactRefsByNode[nodeId] ?? const <String>[]);
  }
}

class KernelGraphNodeExecutionResult {
  const KernelGraphNodeExecutionResult({
    required this.summary,
    this.outputRefs = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String summary;
  final List<String> outputRefs;
  final Map<String, dynamic> metadata;
}
