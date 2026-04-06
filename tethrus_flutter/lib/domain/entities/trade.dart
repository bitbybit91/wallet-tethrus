import 'package:equatable/equatable.dart';

enum TradeStatus {
  initiated,
  escrowLocked,
  paymentSent,
  paymentConfirmed,
  completed,
  cancelled,
  disputed,
  disputeResolved,
}

class Trade extends Equatable {
  final String id;
  final String offerId;
  final String buyerId;
  final String sellerId;
  final String buyerNickname;
  final String sellerNickname;
  final double amount;
  final double fiatAmount;
  final String fiatCurrency;
  final String paymentMethod;
  final TradeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? escrowLockedAt;
  final DateTime? paymentSentAt;
  final DateTime? completedAt;
  final String? escrowTxHash;
  final String? releaseTxHash;

  const Trade({
    required this.id,
    required this.offerId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerNickname,
    required this.sellerNickname,
    required this.amount,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.escrowLockedAt,
    this.paymentSentAt,
    this.completedAt,
    this.escrowTxHash,
    this.releaseTxHash,
  });

  bool get isActive => status != TradeStatus.completed &&
      status != TradeStatus.cancelled &&
      status != TradeStatus.disputeResolved;

  @override
  List<Object?> get props => [id, status, updatedAt];
}
