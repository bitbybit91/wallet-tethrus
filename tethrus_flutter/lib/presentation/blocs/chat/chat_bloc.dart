import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/repositories/chat_repository.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatLoadMessages extends ChatEvent {
  final String tradeId;
  const ChatLoadMessages({required this.tradeId});
  @override
  List<Object?> get props => [tradeId];
}

class ChatSendMessage extends ChatEvent {
  final String tradeId;
  final String content;
  const ChatSendMessage({required this.tradeId, required this.content});
  @override
  List<Object?> get props => [tradeId, content];
}

class ChatMessageReceived extends ChatEvent {
  final ChatMessage message;
  const ChatMessageReceived({required this.message});
  @override
  List<Object?> get props => [message];
}

class ChatMarkAsRead extends ChatEvent {
  final String tradeId;
  const ChatMarkAsRead({required this.tradeId});
  @override
  List<Object?> get props => [tradeId];
}

// State
class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final int unreadCount;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final String? activeTradeId;

  const ChatState({
    this.messages = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
    this.activeTradeId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    int? unreadCount,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    String? activeTradeId,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      activeTradeId: activeTradeId ?? this.activeTradeId,
    );
  }

  @override
  List<Object?> get props => [
        messages, unreadCount, isLoading, isSending, errorMessage, activeTradeId,
      ];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  StreamSubscription<ChatMessage>? _messageSubscription;

  ChatBloc({required this.chatRepository}) : super(const ChatState()) {
    on<ChatLoadMessages>(_onLoadMessages);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatMessageReceived>(_onMessageReceived);
    on<ChatMarkAsRead>(_onMarkAsRead);
  }

  Future<void> _onLoadMessages(
    ChatLoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, activeTradeId: event.tradeId, clearError: true));
    try {
      final messages = await chatRepository.getMessages(event.tradeId);
      final unreadCount = await chatRepository.getUnreadCount();
      emit(state.copyWith(
        messages: messages,
        unreadCount: unreadCount,
        isLoading: false,
      ));

      await _messageSubscription?.cancel();
      _messageSubscription = chatRepository.messageStream(event.tradeId).listen(
        (message) => add(ChatMessageReceived(message: message)),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isSending: true));
    try {
      await chatRepository.sendMessage(
        tradeId: event.tradeId,
        content: event.content,
      );
      emit(state.copyWith(isSending: false));
    } catch (e) {
      emit(state.copyWith(isSending: false, errorMessage: e.toString()));
    }
  }

  void _onMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final updatedMessages = [...state.messages, event.message];
    emit(state.copyWith(messages: updatedMessages));
  }

  Future<void> _onMarkAsRead(
    ChatMarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    await chatRepository.markAsRead(event.tradeId);
    final unreadCount = await chatRepository.getUnreadCount();
    emit(state.copyWith(unreadCount: unreadCount));
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
