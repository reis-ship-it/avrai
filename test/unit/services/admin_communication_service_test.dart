import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/core/services/admin/admin_communication_service.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import 'package:avrai/core/ai/ai2ai_learning.dart';

import 'admin_communication_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([ConnectionMonitor, AI2AIChatAnalyzer])
void main() {
  group('AdminCommunicationService Tests', () {
    late AdminCommunicationService service;
    late MockConnectionMonitor mockConnectionMonitor;
    late MockAI2AIChatAnalyzer mockChatAnalyzer;

    setUp(() {
      mockConnectionMonitor = MockConnectionMonitor();
      mockChatAnalyzer = MockAI2AIChatAnalyzer();

      service = AdminCommunicationService(
        connectionMonitor: mockConnectionMonitor,
        chatAnalyzer: mockChatAnalyzer,
      );
    });

    group('getConnectionLog', () {
      test('should return connection log for connection ID', () async {
        const connectionId = 'connection-123';

        when(mockConnectionMonitor.getConnectionStatus(connectionId))
            .thenAnswer((_) async => ConnectionMonitoringStatus.notFound(connectionId));
        when(mockConnectionMonitor.getMonitoringSession(connectionId))
            .thenReturn(null);
        when(mockChatAnalyzer.getAllChatHistoryForAdmin())
            .thenReturn({});

        final log = await service.getConnectionLog(connectionId);

        expect(log, isA<ConnectionCommunicationLog>());
        expect(log.connectionId, equals(connectionId));
      });

      test('should return empty log when connection not found', () async {
        const connectionId = 'non-existent';

        when(mockConnectionMonitor.getConnectionStatus(connectionId))
            .thenAnswer((_) async => ConnectionMonitoringStatus.notFound(connectionId));
        when(mockConnectionMonitor.getMonitoringSession(connectionId))
            .thenReturn(null);
        when(mockChatAnalyzer.getAllChatHistoryForAdmin())
            .thenReturn({});

        final log = await service.getConnectionLog(connectionId);

        expect(log, isA<ConnectionCommunicationLog>());
        expect(log.chatEvents, isEmpty);
        expect(log.interactionHistory, isEmpty);
      });
    });

    group('getAllConnectionSummaries', () {
      test('should return summaries for all active connections', () async {
        final overview = ActiveConnectionsOverview.empty();

        when(mockConnectionMonitor.getActiveConnectionsOverview())
            .thenAnswer((_) async => overview);
        when(mockConnectionMonitor.getConnectionStatus(any))
            .thenAnswer((_) async => ConnectionMonitoringStatus.notFound('conn-1'));
        when(mockConnectionMonitor.getMonitoringSession(any))
            .thenReturn(null);
        when(mockChatAnalyzer.getAllChatHistoryForAdmin())
            .thenReturn({});

        final summaries = await service.getAllConnectionSummaries();

        expect(summaries, isA<List<ConnectionCommunicationSummary>>());
      });
    });

    group('searchLogs', () {
      test('should search logs by connection ID', () async {
        final overview = ActiveConnectionsOverview.empty();

        when(mockConnectionMonitor.getActiveConnectionsOverview())
            .thenAnswer((_) async => overview);
        when(mockConnectionMonitor.getConnectionStatus(any))
            .thenAnswer((_) async => ConnectionMonitoringStatus.notFound('conn-1'));
        when(mockConnectionMonitor.getMonitoringSession(any))
            .thenReturn(null);
        when(mockChatAnalyzer.getAllChatHistoryForAdmin())
            .thenReturn({});

        final logs = await service.searchLogs(connectionId: 'conn-1');

        expect(logs, isA<List<ConnectionCommunicationLog>>());
      });

      test('should filter logs by time range', () async {
        final overview = ActiveConnectionsOverview.empty();

        when(mockConnectionMonitor.getActiveConnectionsOverview())
            .thenAnswer((_) async => overview);
        when(mockConnectionMonitor.getConnectionStatus(any))
            .thenAnswer((_) async => ConnectionMonitoringStatus.notFound('conn-1'));
        when(mockConnectionMonitor.getMonitoringSession(any))
            .thenReturn(null);
        when(mockChatAnalyzer.getAllChatHistoryForAdmin())
            .thenReturn({});

        final startTime = DateTime.now().subtract(const Duration(days: 1));
        final endTime = DateTime.now();

        final logs = await service.searchLogs(
          startTime: startTime,
          endTime: endTime,
        );

        expect(logs, isA<List<ConnectionCommunicationLog>>());
      });
    });

  tearDownAll(() async {
    await cleanupTestStorage();
  });
  });
}

