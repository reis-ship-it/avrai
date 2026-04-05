import 'dart:convert';

import 'package:avrai_core/avra_core.dart';

class BhamReplaySourcePackService {
  const BhamReplaySourcePackService();

  ReplaySourcePack parsePackJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('Replay source pack must be a JSON object.');
    }
    return ReplaySourcePack.fromJson(
      decoded.map((key, value) => MapEntry('$key', value)),
    );
  }

  Map<String, List<Map<String, dynamic>>> toRawRecordsBySourceName(
    ReplaySourcePack pack,
  ) {
    return <String, List<Map<String, dynamic>>>{
      for (final dataset in pack.datasets)
        dataset.sourceName: dataset.records,
    };
  }
}
