import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'dart:developer' as developer;

class DeviceNotificationPayload extends RawDataPayload {
  final String _content;

  const DeviceNotificationPayload({
    required super.capturedAt,
    required super.sourceId,
    required String content,
  }) : _content = content;

  @override
  String get rawContent => _content;
}

/// The Device Intake Router listens for OS-level events (e.g. Calendar, Notifications).
///
/// It immediately packages the raw OS data into a [RawDataPayload] and passes it
/// entirely off to the [AirGapContract] for semantic extraction.
/// The Router deliberately does NOT return or keep the raw data.
class DeviceIntakeRouter {
  final AirGapContract _airGap;

  DeviceIntakeRouter(this._airGap);

  /// Simulates catching an OS notification and immediately burning it in the Air Gap.
  Future<void> onNotificationReceived(String osNotificationText) async {
    developer.log('DeviceIntakeRouter: Caught incoming OS notification.',
        name: 'IntakeRouter');

    // 1. Wrap the highly sensitive string in a Payload.
    final payload = DeviceNotificationPayload(
      capturedAt: DateTime.now(),
      sourceId: 'os_notification_listener',
      content: osNotificationText,
    );

    try {
      // 2. Pass it over the boundary. The Air Gap takes custody of the raw string.
      developer.log(
          'DeviceIntakeRouter: Passing raw payload to Air Gap scrubber...',
          name: 'IntakeRouter');
      final List<SemanticTuple> tuples = await _airGap.scrubAndExtract(payload);

      // 3. The raw string is gone. We only have tuplified knowledge.
      developer.log(
          'DeviceIntakeRouter: Successfully received ${tuples.length} abstract semantic tuples from Air Gap.',
          name: 'IntakeRouter');

      // In a full implementation, the Router would merely confirm ingestion to the OS,
      // and the Engine would have stored the tuples.
    } on PrivacyBreachException catch (e) {
      developer.log(
          'DeviceIntakeRouter: Air Gap aborted the intake! Reason: $e',
          name: 'IntakeRouter');
    } catch (e) {
      developer.log(
          'DeviceIntakeRouter: Unknown failure during air gap crossing: $e',
          name: 'IntakeRouter');
    }
  }
}
