import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/offer.dart';
import '../../../domain/repositories/market_repository.dart';

// Events
abstract class MarketEvent extends Equatable {
  const MarketEvent();
  @override
  List<Object?> get props => [];
}

class MarketLoadRequested extends MarketEvent {
  final TradeType? tradeType;
  final String? paymentMethod;
  final String? fiatCurrency;
  const MarketLoadRequested({this.tradeType, this.paymentMethod, this.fiatCurrency});
  @override
  List<Object?> get props => [tradeType, paymentMethod, fiatCurrency];
}

class MarketRefreshRequested extends MarketEvent {
  const MarketRefreshRequested();
}

class MarketLoadMoreRequested extends MarketEvent {
  const MarketLoadMoreRequested();
}

class MarketFilterChanged extends MarketEvent {
  final TradeType? tradeType;
  final String? paymentMethod;
  final String? fiatCurrency;
  const MarketFilterChanged({this.tradeType, this.paymentMethod, this.fiatCurrency});
  @override
  List<Object?> get props => [tradeType, paymentMethod, fiatCurrency];
}

class MarketOfferSelected extends MarketEvent {
  final String offerId;
  const MarketOfferSelected({required this.offerId});
  @override
  List<Object?> get props => [offerId];
}

// State
class MarketState extends Equatable {
  final List<Offer> offers;
  final Offer? selectedOffer;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final String? errorMessage;
  final TradeType? filterTradeType;
  final String? filterPaymentMethod;
  final String? filterFiatCurrency;
  final int currentPage;

  const MarketState({
    this.offers = const [],
    this.selectedOffer,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.errorMessage,
    this.filterTradeType,
    this.filterPaymentMethod,
    this.filterFiatCurrency,
    this.currentPage = 0,
  });

  MarketState copyWith({
    List<Offer>? offers,
    Offer? selectedOffer,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedMax,
    String? errorMessage,
    TradeType? filterTradeType,
    String? filterPaymentMethod,
    String? filterFiatCurrency,
    int? currentPage,
    bool clearError = false,
    bool clearSelectedOffer = false,
    bool clearTradeType = false,
    bool clearPaymentMethod = false,
    bool clearFiatCurrency = false,
  }) {
    return MarketState(
      offers: offers ?? this.offers,
      selectedOffer: clearSelectedOffer ? null : selectedOffer ?? this.selectedOffer,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filterTradeType: clearTradeType ? null : filterTradeType ?? this.filterTradeType,
      filterPaymentMethod: clearPaymentMethod ? null : filterPaymentMethod ?? this.filterPaymentMethod,
      filterFiatCurrency: clearFiatCurrency ? null : filterFiatCurrency ?? this.filterFiatCurrency,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
        offers, selectedOffer, isLoading, isLoadingMore, hasReachedMax,
        errorMessage, filterTradeType, filterPaymentMethod, filterFiatCurrency,
        currentPage,
      ];
}

// BLoC
class MarketBloc extends Bloc<MarketEvent, MarketState> {
  final MarketRepository marketRepository;

  MarketBloc({required this.marketRepository}) : super(const MarketState()) {
    on<MarketLoadRequested>(_onLoadRequested);
    on<MarketRefreshRequested>(_onRefreshRequested);
    on<MarketLoadMoreRequested>(_onLoadMoreRequested);
    on<MarketFilterChanged>(_onFilterChanged);
    on<MarketOfferSelected>(_onOfferSelected);
  }

  Future<void> _onLoadRequested(
    MarketLoadRequested event,
    Emitter<MarketState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final offers = await marketRepository.getOffers(
        tradeType: event.tradeType ?? state.filterTradeType,
        paymentMethod: event.paymentMethod ?? state.filterPaymentMethod,
        fiatCurrency: event.fiatCurrency ?? state.filterFiatCurrency,
        page: 0,
      );
      emit(state.copyWith(
        offers: offers,
        isLoading: false,
        currentPage: 0,
        hasReachedMax: offers.length < 20,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    MarketRefreshRequested event,
    Emitter<MarketState> emit,
  ) async {
    try {
      final offers = await marketRepository.getOffers(
        tradeType: state.filterTradeType,
        paymentMethod: state.filterPaymentMethod,
        fiatCurrency: state.filterFiatCurrency,
        page: 0,
      );
      emit(state.copyWith(
        offers: offers,
        currentPage: 0,
        hasReachedMax: offers.length < 20,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    MarketLoadMoreRequested event,
    Emitter<MarketState> emit,
  ) async {
    if (state.hasReachedMax || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.currentPage + 1;
      final offers = await marketRepository.getOffers(
        tradeType: state.filterTradeType,
        paymentMethod: state.filterPaymentMethod,
        fiatCurrency: state.filterFiatCurrency,
        page: nextPage,
      );
      emit(state.copyWith(
        offers: [...state.offers, ...offers],
        isLoadingMore: false,
        currentPage: nextPage,
        hasReachedMax: offers.length < 20,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onFilterChanged(
    MarketFilterChanged event,
    Emitter<MarketState> emit,
  ) async {
    emit(state.copyWith(
      filterTradeType: event.tradeType,
      filterPaymentMethod: event.paymentMethod,
      filterFiatCurrency: event.fiatCurrency,
      clearTradeType: event.tradeType == null,
      clearPaymentMethod: event.paymentMethod == null,
      clearFiatCurrency: event.fiatCurrency == null,
      isLoading: true,
    ));
    add(MarketLoadRequested(
      tradeType: event.tradeType,
      paymentMethod: event.paymentMethod,
      fiatCurrency: event.fiatCurrency,
    ));
  }

  Future<void> _onOfferSelected(
    MarketOfferSelected event,
    Emitter<MarketState> emit,
  ) async {
    try {
      final offer = await marketRepository.getOffer(event.offerId);
      emit(state.copyWith(selectedOffer: offer));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
