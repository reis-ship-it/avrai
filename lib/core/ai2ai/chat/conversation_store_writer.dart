import 'package:get_storage/get_storage.dart';

class ConversationStoreWriter {
  const ConversationStoreWriter._();

  static Future<void> appendMessage({
    required String boxName,
    required String conversationId,
    required Map<String, dynamic> messageJson,
  }) async {
    final box = GetStorage(boxName);
    final key = 'messages_$conversationId';
    final List<dynamic> existing = box.read<List<dynamic>>(key) ?? [];
    existing.add(messageJson);
    await box.write(key, existing);
  }
}
