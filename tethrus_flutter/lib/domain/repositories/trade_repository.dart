import '../entities/trade.dart';

abstract class TradeRepository {
  Future<Trade> initiateTrade({
    required String offerId,
    required double amount,
  });
  Future<Trade> getTrade(String tradeId);
  Future<List<Trade>> getActiveTrades();
  Future<List<Trade>> getTradeHistory();
  Future<void> markPaymentSent(String tradeId);
  Future<void> confirmPaymentReceived(String tradeId);
  Future<void> cancelTrade(String tradeId);
  Future<void> openDispute(String tradeId, String reason);
  Future<void> leaveFeedback({
    required String tradeId,
    required bool isPositive,
    String? comment,
  });
}
