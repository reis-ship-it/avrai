// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
class ForwardedPayloadBuilder {
  const ForwardedPayloadBuilder._();

  static Map<String, dynamic> withHopAndOrigin({
    required Map<String, dynamic> source,
    required int hop,
    required String? originId,
  }) {
    final forwardedPayload = Map<String, dynamic>.from(source);
    forwardedPayload['hop'] = hop + 1;
    forwardedPayload['origin_id'] = originId;
    return forwardedPayload;
  }
}
