import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String tradeId;
  final String senderId;
  final String senderNickname;
  final String encryptedContent;
  final String? decryptedContent;
  final bool isEncrypted;
  final bool isSystemMessage;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.tradeId,
    required this.senderId,
    required this.senderNickname,
    required this.encryptedContent,
    this.decryptedContent,
    this.isEncrypted = true,
    this.isSystemMessage = false,
    required this.timestamp,
    this.isRead = false,
  });

  ChatMessage copyWith({
    String? decryptedContent,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id,
      tradeId: tradeId,
      senderId: senderId,
      senderNickname: senderNickname,
      encryptedContent: encryptedContent,
      decryptedContent: decryptedContent ?? this.decryptedContent,
      isEncrypted: isEncrypted,
      isSystemMessage: isSystemMessage,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, tradeId, timestamp];
}
