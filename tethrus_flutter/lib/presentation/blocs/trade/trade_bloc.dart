import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/trade.dart';
import '../../../domain/repositories/trade_repository.dart';

// Events
abstract class TradeEvent extends Equatable {
  const TradeEvent();
  @override
  List<Object?> get props => [];
}

class TradeLoadRequested extends TradeEvent {
  const TradeLoadRequested();
}

class TradeInitiated extends TradeEvent {
  final String offerId;
  final double amount;
  const TradeInitiated({required this.offerId, required this.amount});
  @override
  List<Object?> get props => [offerId, amount];
}

class TradePaymentMarkedSent extends TradeEvent {
  final String tradeId;
  const TradePaymentMarkedSent({required this.tradeId});
  @override
  List<Object?> get props => [tradeId];
}

class TradePaymentConfirmed extends TradeEvent {
  final String tradeId;
  const TradePaymentConfirmed({required this.tradeId});
  @override
  List<Object?> get props => [tradeId];
}

class TradeCancelled extends TradeEvent {
  final String tradeId;
  const TradeCancelled({required this.tradeId});
  @override
  List<Object?> get props => [tradeId];
}

class TradeDisputeOpened extends TradeEvent {
  final String tradeId;
  final String reason;
  const TradeDisputeOpened({required this.tradeId, required this.reason});
  @override
  List<Object?> get props => [tradeId, reason];
}

// State
class TradeState extends Equatable {
  final List<Trade> activeTrades;
  final List<Trade> tradeHistory;
  final Trade? currentTrade;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const TradeState({
    this.activeTrades = const [],
    this.tradeHistory = const [],
    this.currentTrade,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  TradeState copyWith({
    List<Trade>? activeTrades,
    List<Trade>? tradeHistory,
    Trade? currentTrade,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearCurrentTrade = false,
  }) {
    return TradeState(
      activeTrades: activeTrades ?? this.activeTrades,
      tradeHistory: tradeHistory ?? this.tradeHistory,
      currentTrade: clearCurrentTrade ? null : currentTrade ?? this.currentTrade,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        activeTrades, tradeHistory, currentTrade, isLoading,
        errorMessage, successMessage,
      ];
}

// BLoC
class TradeBloc extends Bloc<TradeEvent, TradeState> {
  final TradeRepository tradeRepository;

  TradeBloc({required this.tradeRepository}) : super(const TradeState()) {
    on<TradeLoadRequested>(_onLoadRequested);
    on<TradeInitiated>(_onTradeInitiated);
    on<TradePaymentMarkedSent>(_onPaymentMarkedSent);
    on<TradePaymentConfirmed>(_onPaymentConfirmed);
    on<TradeCancelled>(_onTradeCancelled);
    on<TradeDisputeOpened>(_onDisputeOpened);
  }

  Future<void> _onLoadRequested(
    TradeLoadRequested event,
    Emitter<TradeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final active = await tradeRepository.getActiveTrades();
      final history = await tradeRepository.getTradeHistory();
      emit(state.copyWith(
        activeTrades: active,
        tradeHistory: history,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onTradeInitiated(
    TradeInitiated event,
    Emitter<TradeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final trade = await tradeRepository.initiateTrade(
        offerId: event.offerId,
        amount: event.amount,
      );
      emit(state.copyWith(
        currentTrade: trade,
        activeTrades: [trade, ...state.activeTrades],
        isLoading: false,
        successMessage: 'Trade initiated successfully',
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onPaymentMarkedSent(
    TradePaymentMarkedSent event,
    Emitter<TradeState> emit,
  ) async {
    try {
      await tradeRepository.markPaymentSent(event.tradeId);
      emit(state.copyWith(successMessage: 'Payment marked as sent'));
      add(const TradeLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onPaymentConfirmed(
    TradePaymentConfirmed event,
    Emitter<TradeState> emit,
  ) async {
    try {
      await tradeRepository.confirmPaymentReceived(event.tradeId);
      emit(state.copyWith(successMessage: 'Payment confirmed'));
      add(const TradeLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onTradeCancelled(
    TradeCancelled event,
    Emitter<TradeState> emit,
  ) async {
    try {
      await tradeRepository.cancelTrade(event.tradeId);
      emit(state.copyWith(successMessage: 'Trade cancelled'));
      add(const TradeLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onDisputeOpened(
    TradeDisputeOpened event,
    Emitter<TradeState> emit,
  ) async {
    try {
      await tradeRepository.openDispute(event.tradeId, event.reason);
      emit(state.copyWith(successMessage: 'Dispute opened'));
      add(const TradeLoadRequested());
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
