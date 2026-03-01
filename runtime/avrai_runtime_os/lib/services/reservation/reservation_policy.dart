import 'package:avrai_core/models/misc/reservation.dart';

class ReservationPolicy {
  const ReservationPolicy();

  bool canModify(Reservation reservation) => reservation.canModify();

  bool canCancel(Reservation reservation) => reservation.canCancel();

  String? modificationBlockReason(Reservation reservation) {
    if (reservation.modificationCount >= 3) {
      return 'Maximum 3 modifications allowed';
    }

    if (DateTime.now().difference(reservation.reservationTime).inHours > -1) {
      return 'Cannot modify within 1 hour of reservation time';
    }

    if (reservation.status == ReservationStatus.cancelled) {
      return 'Reservation is cancelled';
    }

    if (reservation.status == ReservationStatus.completed) {
      return 'Reservation is completed';
    }

    return 'Reservation cannot be modified';
  }
}
