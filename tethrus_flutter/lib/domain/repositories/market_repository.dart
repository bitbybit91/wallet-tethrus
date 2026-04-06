import '../entities/offer.dart';

abstract class MarketRepository {
  Future<List<Offer>> getOffers({
    TradeType? tradeType,
    String? paymentMethod,
    String? fiatCurrency,
    double? amount,
    String? sortBy,
    int page = 0,
    int pageSize = 20,
  });
  Future<Offer> getOffer(String offerId);
  Future<Offer> createOffer(Offer offer);
  Future<Offer> updateOffer(Offer offer);
  Future<void> deleteOffer(String offerId);
  Future<List<Offer>> getMyOffers();
}
