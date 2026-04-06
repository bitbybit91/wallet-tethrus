import '../../domain/entities/offer.dart';
import '../../domain/repositories/market_repository.dart';
import '../datasources/remote/market_api_service.dart';

class MarketRepositoryImpl implements MarketRepository {
  final MarketApiService marketApi;

  MarketRepositoryImpl({required this.marketApi});

  @override
  Future<List<Offer>> getOffers({
    TradeType? tradeType,
    String? paymentMethod,
    String? fiatCurrency,
    double? amount,
    String? sortBy,
    int page = 0,
    int pageSize = 20,
  }) async {
    return marketApi.getOffers(
      tradeType: tradeType,
      paymentMethod: paymentMethod,
      fiatCurrency: fiatCurrency,
      amount: amount,
      sortBy: sortBy,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Offer> getOffer(String offerId) async {
    return marketApi.getOffer(offerId);
  }

  @override
  Future<Offer> createOffer(Offer offer) async {
    return marketApi.createOffer(offer);
  }

  @override
  Future<Offer> updateOffer(Offer offer) async {
    return marketApi.updateOffer(offer);
  }

  @override
  Future<void> deleteOffer(String offerId) async {
    return marketApi.deleteOffer(offerId);
  }

  @override
  Future<List<Offer>> getMyOffers() async {
    final allOffers = await marketApi.getOffers();
    return allOffers.where((o) => o.traderId == 'local_user').toList();
  }
}
