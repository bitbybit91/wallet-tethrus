import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> getMessages(String tradeId);
  Future<ChatMessage> sendMessage({
    required String tradeId,
    required String content,
  });
  Stream<ChatMessage> messageStream(String tradeId);
  Future<void> markAsRead(String tradeId);
  Future<int> getUnreadCount();
  Future<List<String>> getActiveThreadIds();
}
