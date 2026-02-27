class EventModeBroadcastFlagsLane {
  const EventModeBroadcastFlagsLane._();

  static Future<({bool eventModeEnabled, bool connectOk, bool brownout})>
      maybeUpdate({
    required bool hasRequiredContext,
    required bool currentEventModeEnabled,
    required bool currentConnectOk,
    required bool currentBrownout,
    required bool nextEventModeEnabled,
    required bool nextConnectOk,
    required bool nextBrownout,
    required Future<void> Function({
      required bool eventModeEnabled,
      required bool connectOk,
      required bool brownout,
    })
    updateServiceDataFrameV1Flags,
  }) async {
    if (!hasRequiredContext) {
      return (
        eventModeEnabled: currentEventModeEnabled,
        connectOk: currentConnectOk,
        brownout: currentBrownout,
      );
    }

    if (currentEventModeEnabled == nextEventModeEnabled &&
        currentConnectOk == nextConnectOk &&
        currentBrownout == nextBrownout) {
      return (
        eventModeEnabled: currentEventModeEnabled,
        connectOk: currentConnectOk,
        brownout: currentBrownout,
      );
    }

    await updateServiceDataFrameV1Flags(
      eventModeEnabled: nextEventModeEnabled,
      connectOk: nextConnectOk,
      brownout: nextBrownout,
    );

    return (
      eventModeEnabled: nextEventModeEnabled,
      connectOk: nextConnectOk,
      brownout: nextBrownout,
    );
  }
}
