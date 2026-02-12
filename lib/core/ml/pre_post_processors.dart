import 'dart:typed_data';

class MLPPreprocessor {
  // For the demo MLP: pass-through 1x4 float32
  static Float32List toInput1x4(List<double> values) {
    if (values.length != 4) {
      throw ArgumentError('Expected 4 values, got ${values.length}');
    }
    return Float32List.fromList(values.map((e) => e.toDouble()).toList());
  }
}

class MLPPostprocessor {
  // Convert Float32List logits [1x3] to List<double>
  static List<double> fromOutput1x3(Object? tensor) {
    if (tensor is Float32List) {
      return tensor.toList();
    }
    if (tensor is List) {
      return tensor.map((e) => (e as num).toDouble()).toList();
    }
    throw ArgumentError('Unsupported output tensor type: ${tensor.runtimeType}');
  }
}


