import 'package:equatable/equatable.dart';

enum TradeType { buy, sell }

enum OfferStatus { active, paused, closed }

class Offer extends Equatable {
  final String id;
  final String traderId;
  final String traderNickname;
  final TradeType tradeType;
  final String paymentMethod;
  final String fiatCurrency;
  final double pricePerUsdt;
  final double marginPercent;
  final double minAmount;
  final double maxAmount;
  final String terms;
  final String? location;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double traderRating;
  final int traderTradeCount;
  final bool traderOnline;

  const Offer({
    required this.id,
    required this.traderId,
    required this.traderNickname,
    required this.tradeType,
    required this.paymentMethod,
    required this.fiatCurrency,
    required this.pricePerUsdt,
    required this.marginPercent,
    required this.minAmount,
    required this.maxAmount,
    required this.terms,
    this.location,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.traderRating,
    required this.traderTradeCount,
    required this.traderOnline,
  });

  @override
  List<Object?> get props => [
        id, traderId, tradeType, paymentMethod, fiatCurrency,
        pricePerUsdt, marginPercent, minAmount, maxAmount, status,
      ];
}
