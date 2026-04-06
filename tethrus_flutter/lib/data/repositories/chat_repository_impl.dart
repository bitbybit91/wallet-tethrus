import 'dart:async';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Map<String, List<ChatMessage>> _messages = {};
  final _messageController = StreamController<ChatMessage>.broadcast();
  int _messageIdCounter = 0;

  @override
  Future<List<ChatMessage>> getMessages(String tradeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _messages[tradeId] ?? [];
  }

  @override
  Future<ChatMessage> sendMessage({
    required String tradeId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _messageIdCounter++;
    final message = ChatMessage(
      id: 'msg_$_messageIdCounter',
      tradeId: tradeId,
      senderId: 'local_user',
      senderNickname: 'You',
      encryptedContent: content,
      decryptedContent: content,
      isEncrypted: true,
      timestamp: DateTime.now(),
      isRead: true,
    );

    _messages.putIfAbsent(tradeId, () => []);
    _messages[tradeId]!.add(message);
    _messageController.add(message);
    return message;
  }

  @override
  Stream<ChatMessage> messageStream(String tradeId) {
    return _messageController.stream
        .where((msg) => msg.tradeId == tradeId);
  }

  @override
  Future<void> markAsRead(String tradeId) async {
    final messages = _messages[tradeId];
    if (messages != null) {
      for (int i = 0; i < messages.length; i++) {
        messages[i] = messages[i].copyWith(isRead: true);
      }
    }
  }

  @override
  Future<int> getUnreadCount() async {
    int count = 0;
    for (final msgs in _messages.values) {
      count += msgs.where((m) => !m.isRead).length;
    }
    return count;
  }

  @override
  Future<List<String>> getActiveThreadIds() async {
    return _messages.keys.toList();
  }
}
