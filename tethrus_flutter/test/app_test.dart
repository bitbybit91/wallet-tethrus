import 'package:flutter_test/flutter_test.dart';
import 'package:tethrus/core/constants/app_constants.dart';
import 'package:tethrus/domain/entities/offer.dart';
import 'package:tethrus/domain/entities/trade.dart';
import 'package:tethrus/domain/entities/wallet_account.dart';

void main() {
  group('AppConstants', () {
    test('app name is Tethrus', () {
      expect(AppConstants.appName, equals('Tethrus'));
    });

    test('package name is com.tethrus.app', () {
      expect(AppConstants.packageName, equals('com.tethrus.app'));
    });

    test('USDT contract address is correct', () {
      expect(
        AppConstants.usdtContractAddress,
        equals('TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t'),
      );
    });

    test('TronGrid API URL is mainnet', () {
      expect(
        AppConstants.tronGridApiUrl,
        equals('https://api.trongrid.io'),
      );
    });

    test('supported fiat currencies is not empty', () {
      expect(AppConstants.supportedFiatCurrencies, isNotEmpty);
      expect(AppConstants.supportedFiatCurrencies, contains('USD'));
      expect(AppConstants.supportedFiatCurrencies, contains('EUR'));
    });

    test('payment methods include Bank Transfer', () {
      expect(AppConstants.paymentMethods, contains('Bank Transfer'));
    });
  });

  group('Offer entity', () {
    test('creates offer with required fields', () {
      final offer = Offer(
        id: 'test',
        traderId: 'trader1',
        traderNickname: 'TestTrader',
        tradeType: TradeType.buy,
        paymentMethod: 'Bank Transfer',
        fiatCurrency: 'USD',
        pricePerUsdt: 1.02,
        marginPercent: 2.0,
        minAmount: 100,
        maxAmount: 5000,
        terms: 'Fast payment',
        status: OfferStatus.active,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        traderRating: 0.95,
        traderTradeCount: 50,
        traderOnline: true,
      );
      expect(offer.id, equals('test'));
      expect(offer.tradeType, equals(TradeType.buy));
    });
  });

  group('Trade entity', () {
    test('isActive returns true for initiated trade', () {
      final trade = Trade(
        id: 'trade1',
        offerId: 'offer1',
        buyerId: 'buyer1',
        sellerId: 'seller1',
        buyerNickname: 'Buyer',
        sellerNickname: 'Seller',
        amount: 100,
        fiatAmount: 102,
        fiatCurrency: 'USD',
        paymentMethod: 'Bank Transfer',
        status: TradeStatus.initiated,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      expect(trade.isActive, isTrue);
    });

    test('isActive returns false for completed trade', () {
      final trade = Trade(
        id: 'trade2',
        offerId: 'offer1',
        buyerId: 'buyer1',
        sellerId: 'seller1',
        buyerNickname: 'Buyer',
        sellerNickname: 'Seller',
        amount: 100,
        fiatAmount: 102,
        fiatCurrency: 'USD',
        paymentMethod: 'Bank Transfer',
        status: TradeStatus.completed,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      expect(trade.isActive, isFalse);
    });
  });

  group('WalletAccount entity', () {
    test('copyWith preserves unchanged fields', () {
      final account = WalletAccount(
        id: 'acc1',
        address: 'TAddr123',
        nickname: 'Main',
        type: WalletAccountType.standard,
        usdtBalance: 100,
        trxBalance: 50,
        isDefault: true,
        createdAt: DateTime(2024),
      );
      final updated = account.copyWith(usdtBalance: 200);
      expect(updated.usdtBalance, equals(200));
      expect(updated.trxBalance, equals(50));
      expect(updated.nickname, equals('Main'));
    });
  });
}

