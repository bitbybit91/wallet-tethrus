import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/wallet_account.dart';
import '../../../domain/entities/wallet_transaction.dart';
import '../../../domain/repositories/wallet_repository.dart';

// Events
abstract class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class WalletLoadRequested extends WalletEvent {
  const WalletLoadRequested();
}

class WalletRefreshRequested extends WalletEvent {
  const WalletRefreshRequested();
}

class WalletSendRequested extends WalletEvent {
  final String toAddress;
  final double amount;
  const WalletSendRequested({required this.toAddress, required this.amount});
  @override
  List<Object?> get props => [toAddress, amount];
}

class WalletCreateRequested extends WalletEvent {
  const WalletCreateRequested();
}

// State
class WalletState extends Equatable {
  final WalletAccount? activeAccount;
  final List<WalletAccount> accounts;
  final List<WalletTransaction> transactions;
  final double estimatedFee;
  final bool isLoading;
  final bool isSending;
  final String? sendResult;
  final String? errorMessage;

  const WalletState({
    this.activeAccount,
    this.accounts = const [],
    this.transactions = const [],
    this.estimatedFee = 0.0,
    this.isLoading = false,
    this.isSending = false,
    this.sendResult,
    this.errorMessage,
  });

  WalletState copyWith({
    WalletAccount? activeAccount,
    List<WalletAccount>? accounts,
    List<WalletTransaction>? transactions,
    double? estimatedFee,
    bool? isLoading,
    bool? isSending,
    String? sendResult,
    String? errorMessage,
    bool clearError = false,
    bool clearSendResult = false,
  }) {
    return WalletState(
      activeAccount: activeAccount ?? this.activeAccount,
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      estimatedFee: estimatedFee ?? this.estimatedFee,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      sendResult: clearSendResult ? null : sendResult ?? this.sendResult,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        activeAccount, accounts, transactions, estimatedFee,
        isLoading, isSending, sendResult, errorMessage,
      ];
}

// BLoC
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository walletRepository;

  WalletBloc({required this.walletRepository}) : super(const WalletState()) {
    on<WalletLoadRequested>(_onLoadRequested);
    on<WalletRefreshRequested>(_onRefreshRequested);
    on<WalletSendRequested>(_onSendRequested);
    on<WalletCreateRequested>(_onCreateRequested);
  }

  Future<void> _onLoadRequested(
    WalletLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final accounts = await walletRepository.getAccounts();
      final defaultAccount = await walletRepository.getDefaultAccount();
      List<WalletTransaction> transactions = [];
      double fee = 0;

      if (defaultAccount != null) {
        await walletRepository.refreshBalances(defaultAccount.address);
        transactions = await walletRepository.getTransactionHistory(
          defaultAccount.address,
        );
        fee = await walletRepository.estimateFee();
        final refreshedAccounts = await walletRepository.getAccounts();
        final refreshedDefault = await walletRepository.getDefaultAccount();
        emit(state.copyWith(
          activeAccount: refreshedDefault,
          accounts: refreshedAccounts,
          transactions: transactions,
          estimatedFee: fee,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          accounts: accounts,
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    WalletRefreshRequested event,
    Emitter<WalletState> emit,
  ) async {
    if (state.activeAccount == null) return;
    try {
      await walletRepository.refreshBalances(state.activeAccount!.address);
      final accounts = await walletRepository.getAccounts();
      final defaultAccount = await walletRepository.getDefaultAccount();
      final transactions = await walletRepository.getTransactionHistory(
        state.activeAccount!.address,
      );
      emit(state.copyWith(
        activeAccount: defaultAccount,
        accounts: accounts,
        transactions: transactions,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onSendRequested(
    WalletSendRequested event,
    Emitter<WalletState> emit,
  ) async {
    if (state.activeAccount == null) return;
    emit(state.copyWith(isSending: true, clearError: true, clearSendResult: true));
    try {
      final txHash = await walletRepository.sendUsdt(
        fromAddress: state.activeAccount!.address,
        toAddress: event.toAddress,
        amount: event.amount,
      );
      emit(state.copyWith(isSending: false, sendResult: txHash));
      add(const WalletRefreshRequested());
    } catch (e) {
      emit(state.copyWith(isSending: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateRequested(
    WalletCreateRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final account = await walletRepository.createWallet();
      emit(state.copyWith(
        activeAccount: account,
        accounts: [account],
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
