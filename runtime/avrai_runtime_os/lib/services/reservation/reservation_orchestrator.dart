import 'package:avrai_core/models/misc/reservation.dart';

class ReservationOrchestrator {
  const ReservationOrchestrator();

  Reservation applyUserUpdate({
    required Reservation existing,
    DateTime? reservationTime,
    int? partySize,
    int? ticketCount,
    String? specialRequests,
    String? calendarEventId,
  }) {
    return existing.copyWith(
      reservationTime: reservationTime ?? existing.reservationTime,
      partySize: partySize ?? existing.partySize,
      ticketCount: ticketCount ?? existing.ticketCount,
      specialRequests: specialRequests ?? existing.specialRequests,
      calendarEventId: calendarEventId ?? existing.calendarEventId,
      modificationCount: existing.modificationCount + 1,
      lastModifiedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Reservation markCancelled(Reservation existing) {
    return existing.copyWith(
      status: ReservationStatus.cancelled,
      updatedAt: DateTime.now(),
    );
  }
}
