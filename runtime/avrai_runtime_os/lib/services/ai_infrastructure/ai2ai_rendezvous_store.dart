import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class Ai2AiRendezvousEntry {
  const Ai2AiRendezvousEntry({
    required this.ticket,
    required this.candidate,
    required this.storedAtUtc,
  });

  final Ai2AiRendezvousTicket ticket;
  final Ai2AiExchangeCandidate candidate;
  final DateTime storedAtUtc;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ticket': ticket.toJson(),
        'candidate': candidate.toJson(),
        'stored_at_utc': storedAtUtc.toUtc().toIso8601String(),
      };

  factory Ai2AiRendezvousEntry.fromJson(Map<String, dynamic> json) {
    return Ai2AiRendezvousEntry(
      ticket: Ai2AiRendezvousTicket.fromJson(
        Map<String, dynamic>.from(
          json['ticket'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      candidate: Ai2AiExchangeCandidate.fromJson(
        Map<String, dynamic>.from(
          json['candidate'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      storedAtUtc:
          DateTime.tryParse(json['stored_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class Ai2AiRendezvousStore {
  Ai2AiRendezvousStore({
    StorageService? storageService,
    DateTime Function()? nowUtc,
    Map<String, Ai2AiRendezvousEntry>? seededEntries,
  })  : _storageService = storageService,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
        _memoryEntries = Map<String, Ai2AiRendezvousEntry>.from(
          seededEntries ?? const <String, Ai2AiRendezvousEntry>{},
        );

  static const String _storageKey = 'ai2ai_rendezvous_store_v1';

  final StorageService? _storageService;
  final DateTime Function() _nowUtc;
  final Map<String, Ai2AiRendezvousEntry> _memoryEntries;

  List<Ai2AiRendezvousEntry> allEntries() {
    final entries = _readEntries().values.toList()
      ..sort((left, right) => left.storedAtUtc.compareTo(right.storedAtUtc));
    return entries;
  }

  Ai2AiRendezvousEntry? entryForTicketId(String ticketId) {
    return _readEntries()[ticketId];
  }

  Ai2AiRendezvousEntry? entryForExchangeId(String exchangeId) {
    for (final entry in _readEntries().values) {
      if (entry.ticket.exchangeId == exchangeId ||
          entry.candidate.exchangeId == exchangeId) {
        return entry;
      }
    }
    return null;
  }

  Ai2AiRendezvousEntry? entryForSubject(String subjectId) {
    for (final entry in _readEntries().values) {
      if (entry.ticket.exchangeId == subjectId ||
          entry.candidate.exchangeId == subjectId ||
          entry.candidate.conversationId == subjectId) {
        return entry;
      }
    }
    return null;
  }

  Future<void> upsert({
    required Ai2AiRendezvousTicket ticket,
    required Ai2AiExchangeCandidate candidate,
  }) async {
    final entries = _readEntries();
    entries[ticket.ticketId] = Ai2AiRendezvousEntry(
      ticket: ticket,
      candidate: candidate,
      storedAtUtc: _nowUtc(),
    );
    await _writeEntries(entries);
  }

  Future<void> removeTicket(String ticketId) async {
    final entries = _readEntries();
    entries.remove(ticketId);
    await _writeEntries(entries);
  }

  Future<void> removeExchange(String exchangeId) async {
    final entries = _readEntries();
    final keysToRemove = entries.entries
        .where(
          (entry) =>
              entry.value.ticket.exchangeId == exchangeId ||
              entry.value.candidate.exchangeId == exchangeId,
        )
        .map((entry) => entry.key)
        .toList();
    for (final key in keysToRemove) {
      entries.remove(key);
    }
    await _writeEntries(entries);
  }

  int activeCount() => _readEntries().length;

  Map<String, Ai2AiRendezvousEntry> _readEntries() {
    final persisted = _readFromStorage();
    if (persisted != null) {
      return persisted;
    }
    return Map<String, Ai2AiRendezvousEntry>.from(_memoryEntries);
  }

  Future<void> _writeEntries(Map<String, Ai2AiRendezvousEntry> entries) async {
    _memoryEntries
      ..clear()
      ..addAll(entries);
    final storage = _storageService;
    if (storage == null) {
      return;
    }
    try {
      await storage.setObject(
        _storageKey,
        entries.map((key, value) => MapEntry(key, value.toJson())),
        box: 'spots_ai',
      );
    } on StateError {
      // Fall back to in-memory behavior if storage is not initialized yet.
    }
  }

  Map<String, Ai2AiRendezvousEntry>? _readFromStorage() {
    final storage = _storageService;
    if (storage == null) {
      return null;
    }
    try {
      final raw = storage.getObject<Map<dynamic, dynamic>>(
        _storageKey,
        box: 'spots_ai',
      );
      if (raw == null) {
        return null;
      }
      return raw.map(
        (key, value) => MapEntry(
          key.toString(),
          Ai2AiRendezvousEntry.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      );
    } on StateError {
      return null;
    }
  }
}
