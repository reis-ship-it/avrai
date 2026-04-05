import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

class ReservationRepositoryAdapter {
  static const String _logName = 'ReservationRepositoryAdapter';

  final StorageService _storageService;
  final String storageKeyPrefix;
  final String supabaseTable;

  const ReservationRepositoryAdapter({
    required StorageService storageService,
    this.storageKeyPrefix = 'reservation_',
    this.supabaseTable = 'reservations',
  }) : _storageService = storageService;

  Future<void> storeLocal(Reservation reservation) async {
    final key = '$storageKeyPrefix${reservation.id}';
    final jsonStr = jsonEncode(reservation.toJson());
    await _storageService.setString(key, jsonStr);
  }

  Future<Reservation?> getById(String reservationId) async {
    final key = '$storageKeyPrefix$reservationId';
    final jsonStr = _storageService.getString(key);
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Reservation.fromJson(json);
    } catch (e) {
      developer.log('Error parsing reservation JSON: $e', name: _logName);
      return null;
    }
  }

  Future<List<Reservation>> getLocal({
    String? agentId,
    ReservationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allKeys = _storageService.getKeys();
      final reservationKeys =
          allKeys.where((key) => key.startsWith(storageKeyPrefix)).toList();

      final reservations = <Reservation>[];
      for (final key in reservationKeys) {
        final jsonStr = _storageService.getString(key);
        if (jsonStr == null) {
          continue;
        }

        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final reservation = Reservation.fromJson(json);

          if (agentId != null && reservation.agentId != agentId) continue;
          if (status != null && reservation.status != status) continue;
          if (startDate != null &&
              reservation.reservationTime.isBefore(startDate)) {
            continue;
          }
          if (endDate != null && reservation.reservationTime.isAfter(endDate)) {
            continue;
          }

          reservations.add(reservation);
        } catch (e) {
          developer.log(
            'Error parsing reservation from local storage: $e',
            name: _logName,
          );
        }
      }

      return reservations;
    } catch (e) {
      developer.log(
        'Error getting reservations from local storage: $e',
        name: _logName,
      );
      return <Reservation>[];
    }
  }

  Future<List<Reservation>> getCloud({
    required SupabaseService supabaseService,
    String? agentId,
    ReservationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!supabaseService.isAvailable) {
      return <Reservation>[];
    }

    try {
      final client = supabaseService.client;
      var query = client.from(supabaseTable).select();

      if (agentId != null) {
        query = query.eq('agent_id', agentId);
      }
      if (status != null) {
        query = query.eq('status', status.name);
      }
      if (startDate != null) {
        query = query.gte('reservation_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('reservation_time', endDate.toIso8601String());
      }

      final response = await query;
      if (response.isEmpty) return <Reservation>[];

      final reservations = <Reservation>[];
      for (final row in response) {
        try {
          final reservation =
              Reservation.fromJson(Map<String, dynamic>.from(row));
          reservations.add(reservation);
        } catch (e) {
          developer.log(
            'Error parsing reservation from cloud: $e',
            name: _logName,
          );
        }
      }
      return reservations;
    } catch (e) {
      developer.log(
        'Error getting reservations from cloud: $e',
        name: _logName,
      );
      return <Reservation>[];
    }
  }

  Future<void> syncToCloud({
    required SupabaseService supabaseService,
    required Reservation reservation,
  }) async {
    if (!supabaseService.isAvailable) {
      return;
    }

    try {
      final client = supabaseService.client;
      await client.from(supabaseTable).upsert({
        'id': reservation.id,
        'agent_id': reservation.agentId,
        'user_data': reservation.userData,
        'type': reservation.type.name,
        'target_id': reservation.targetId,
        'reservation_time': reservation.reservationTime.toIso8601String(),
        'party_size': reservation.partySize,
        'ticket_count': reservation.ticketCount,
        'special_requests': reservation.specialRequests,
        'status': reservation.status.name,
        'ticket_price': reservation.ticketPrice,
        'deposit_amount': reservation.depositAmount,
        'seat_id': reservation.seatId,
        'cancellation_policy': reservation.cancellationPolicy?.toJson(),
        'modification_count': reservation.modificationCount,
        'last_modified_at': reservation.lastModifiedAt?.toIso8601String(),
        'dispute_status': reservation.disputeStatus.name,
        'dispute_reason': reservation.disputeReason?.name,
        'dispute_description': reservation.disputeDescription,
        'atomic_timestamp': reservation.atomicTimestamp?.toJson(),
        'quantum_state': reservation.quantumState?.toJson(),
        'calendar_event_id': reservation.calendarEventId,
        'metadata': reservation.metadata,
        'created_at': reservation.createdAt.toIso8601String(),
        'updated_at': reservation.updatedAt.toIso8601String(),
      });
    } catch (e) {
      developer.log('Error syncing reservation to cloud: $e', name: _logName);
      rethrow;
    }
  }
}
