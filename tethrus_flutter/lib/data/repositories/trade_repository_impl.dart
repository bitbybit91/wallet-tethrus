import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import '../datasources/remote/market_api_service.dart';

class TradeRepositoryImpl implements TradeRepository {
  final MarketApiService marketApi;

  TradeRepositoryImpl({required this.marketApi});

  @override
  Future<Trade> initiateTrade({
    required String offerId,
    required double amount,
  }) async {
    return marketApi.initiateTrade(offerId: offerId, amount: amount);
  }

  @override
  Future<Trade> getTrade(String tradeId) async {
    return marketApi.getTrade(tradeId);
  }

  @override
  Future<List<Trade>> getActiveTrades() async {
    return marketApi.getActiveTrades();
  }

  @override
  Future<List<Trade>> getTradeHistory() async {
    return marketApi.getTradeHistory();
  }

  @override
  Future<void> markPaymentSent(String tradeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> confirmPaymentReceived(String tradeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> cancelTrade(String tradeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> openDispute(String tradeId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> leaveFeedback({
    required String tradeId,
    required bool isPositive,
    String? comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
