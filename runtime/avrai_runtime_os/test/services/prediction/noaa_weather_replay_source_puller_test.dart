import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/noaa_weather_replay_source_puller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('pulls NOAA alert features into replay source records', () async {
    final client = MockClient((http.Request request) async {
      expect(request.url.host, 'api.weather.gov');
      return http.Response(
        '''
{
  "features": [
    {
      "id": "https://api.weather.gov/alerts/123",
      "properties": {
        "headline": "Heat Advisory",
        "event": "Heat Advisory",
        "areaDesc": "Jefferson County; Shelby County",
        "sent": "2023-08-17T13:00:00Z",
        "onset": "2023-08-17T15:00:00Z",
        "effective": "2023-08-17T13:00:00Z",
        "ends": "2023-08-17T21:00:00Z",
        "severity": "Moderate",
        "urgency": "Expected",
        "certainty": "Likely",
        "affectedZones": ["ALZ024"]
      }
    }
  ]
}
''',
        200,
      );
    });

    final puller = NoaaWeatherReplaySourcePuller(client: client);
    final dataset = await puller.pull(
      plan: const ReplaySourcePullPlan(
        sourceName: 'NWS / NOAA Weather API',
        replayYear: 2023,
        acquisitionMode: ReplaySourceAcquisitionMode.automated,
        rawOutputKey: 'nws_noaa_weather_api',
        sourceUrl: 'https://api.weather.gov',
        endpointRef: 'https://api.weather.gov',
      ),
    );

    expect(dataset.sourceName, 'NWS / NOAA Weather API');
    expect(dataset.records.length, 1);
    expect(dataset.records.single['entity_type'], 'environmental_signal');
    expect(dataset.records.single['locality'], 'Jefferson County');
  });
}
