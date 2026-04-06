import 'dart:math';
import '../../../domain/entities/offer.dart';
import '../../../domain/entities/trade.dart';
import '../../../domain/entities/trader_profile.dart';

/// Local mock API service for the P2P marketplace.
/// In production, this would connect to decentralized supernodes.
class MarketApiService {
  final List<Offer> _offers = _generateSampleOffers();
  final List<Trade> _trades = [];

  Future<List<Offer>> getOffers({
    TradeType? tradeType,
    String? paymentMethod,
    String? fiatCurrency,
    double? amount,
    String? sortBy,
    int page = 0,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var filtered = List<Offer>.from(_offers);

    if (tradeType != null) {
      filtered = filtered.where((o) => o.tradeType == tradeType).toList();
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      filtered = filtered
          .where((o) =>
              o.paymentMethod.toLowerCase().contains(paymentMethod.toLowerCase()))
          .toList();
    }
    if (fiatCurrency != null && fiatCurrency.isNotEmpty) {
      filtered =
          filtered.where((o) => o.fiatCurrency == fiatCurrency).toList();
    }
    if (amount != null) {
      filtered = filtered
          .where((o) => o.minAmount <= amount && o.maxAmount >= amount)
          .toList();
    }

    switch (sortBy) {
      case 'price_asc':
        filtered.sort((a, b) => a.pricePerUsdt.compareTo(b.pricePerUsdt));
      case 'price_desc':
        filtered.sort((a, b) => b.pricePerUsdt.compareTo(a.pricePerUsdt));
      case 'rating':
        filtered.sort((a, b) => b.traderRating.compareTo(a.traderRating));
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final start = page * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  Future<Offer> getOffer(String offerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _offers.firstWhere((o) => o.id == offerId);
  }

  Future<Offer> createOffer(Offer offer) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _offers.insert(0, offer);
    return offer;
  }

  Future<Offer> updateOffer(Offer offer) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _offers.indexWhere((o) => o.id == offer.id);
    if (index >= 0) {
      _offers[index] = offer;
    }
    return offer;
  }

  Future<void> deleteOffer(String offerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _offers.removeWhere((o) => o.id == offerId);
  }

  Future<Trade> initiateTrade({
    required String offerId,
    required double amount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final offer = _offers.firstWhere((o) => o.id == offerId);
    final trade = Trade(
      id: 'trade_${DateTime.now().millisecondsSinceEpoch}',
      offerId: offerId,
      buyerId: 'local_user',
      sellerId: offer.traderId,
      buyerNickname: 'You',
      sellerNickname: offer.traderNickname,
      amount: amount,
      fiatAmount: amount * offer.pricePerUsdt,
      fiatCurrency: offer.fiatCurrency,
      paymentMethod: offer.paymentMethod,
      status: TradeStatus.initiated,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _trades.add(trade);
    return trade;
  }

  Future<Trade> getTrade(String tradeId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _trades.firstWhere((t) => t.id == tradeId);
  }

  Future<List<Trade>> getActiveTrades() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _trades.where((t) => t.isActive).toList();
  }

  Future<List<Trade>> getTradeHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _trades.where((t) => !t.isActive).toList();
  }

  static List<Offer> _generateSampleOffers() {
    final random = Random(42);
    final nicknames = [
      'CryptoKing', 'QuickTrader', 'SafeSwap', 'TrustExchange',
      'P2Pmaster', 'CashDeal', 'FastCrypto', 'TetherPro',
      'SwiftTrade', 'CoinBridge', 'AnonExchange', 'SecureDeal',
    ];
    final methods = [
      'Bank Transfer', 'Cash in Person', 'PayPal', 'Revolut',
      'Zelle', 'Wise (TransferWise)', 'Mobile Money', 'Gift Cards',
    ];
    final currencies = ['USD', 'EUR', 'GBP', 'CNY', 'RUB'];
    final offers = <Offer>[];

    for (int i = 0; i < 30; i++) {
      final isBuy = random.nextBool();
      final currency = currencies[random.nextInt(currencies.length)];
      final basePrice = currency == 'USD'
          ? 1.0
          : currency == 'EUR'
              ? 0.92
              : currency == 'GBP'
                  ? 0.79
                  : currency == 'CNY'
                      ? 7.24
                      : 91.5;
      final margin = (random.nextDouble() * 10 - 3);
      final price = basePrice * (1 + margin / 100);

      offers.add(Offer(
        id: 'offer_$i',
        traderId: 'trader_$i',
        traderNickname: nicknames[i % nicknames.length],
        tradeType: isBuy ? TradeType.buy : TradeType.sell,
        paymentMethod: methods[random.nextInt(methods.length)],
        fiatCurrency: currency,
        pricePerUsdt: double.parse(price.toStringAsFixed(4)),
        marginPercent: double.parse(margin.toStringAsFixed(1)),
        minAmount: (random.nextInt(5) + 1) * 50.0,
        maxAmount: (random.nextInt(10) + 5) * 500.0,
        terms: 'Fast payment required. Will release within 15 minutes of confirmed payment.',
        status: OfferStatus.active,
        createdAt: DateTime.now().subtract(Duration(hours: random.nextInt(72))),
        updatedAt: DateTime.now().subtract(Duration(minutes: random.nextInt(60))),
        traderRating: 0.7 + random.nextDouble() * 0.3,
        traderTradeCount: random.nextInt(500) + 10,
        traderOnline: random.nextDouble() > 0.3,
      ));
    }
    return offers;
  }
}
