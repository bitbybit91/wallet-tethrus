class AppConstants {
  AppConstants._();

  // App identity
  static const String appName = 'Tethrus';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.tethrus.app';

  // TRON network - Mainnet
  static const String tronGridApiUrl = 'https://api.trongrid.io';
  static const String tronScanExplorerUrl = 'https://tronscan.org';
  static const String usdtContractAddress =
      'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t';

  // TRON network - Testnet (Nile)
  static const String tronGridTestnetUrl = 'https://nile.trongrid.io';
  static const String tronScanTestnetUrl = 'https://nile.tronscan.org';
  static const String usdtTestnetContract =
      'TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf';

  // Crypto
  static const int tronDecimals = 6;
  static const int usdtDecimals = 6;
  static const String tronBip44Path = "m/44'/195'/0'/0/0";

  // Security defaults
  static const int defaultAutoLockMinutes = 5;
  static const int pinLength = 6;
  static const int mnemonicWordCount = 12;

  // Trade defaults
  static const Duration tradeTimeout = Duration(hours: 2);
  static const Duration sellerResponseTimeout = Duration(minutes: 30);

  // API
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Pagination
  static const int pageSize = 20;

  // Supported fiat currencies
  static const List<String> supportedFiatCurrencies = [
    'USD', 'EUR', 'GBP', 'CNY', 'RUB', 'JPY', 'KRW', 'INR', 'BRL', 'AUD',
    'CAD', 'CHF', 'HKD', 'SGD', 'TWD', 'MXN', 'ZAR', 'NGN', 'AED', 'SAR',
    'THB', 'VND', 'PHP', 'IDR', 'MYR', 'PLN', 'CZK', 'HUF', 'SEK', 'NOK',
    'DKK', 'NZD', 'CLP', 'ARS', 'COP', 'PEN', 'TRY', 'UAH', 'KZT', 'GEL',
    'RON', 'BGN', 'HRK', 'ILS', 'EGP', 'PKR', 'BDT', 'LKR', 'GHS', 'KES',
  ];

  // Payment methods
  static const List<String> paymentMethods = [
    'Bank Transfer',
    'Cash in Person',
    'Cash by Mail',
    'Mobile Money',
    'Gift Cards',
    'Crypto-to-Crypto',
    'PayPal',
    'Venmo',
    'Zelle',
    'Revolut',
    'Wise (TransferWise)',
    'Western Union',
    'MoneyGram',
    'Alipay',
    'WeChat Pay',
    'M-Pesa',
    'SEPA Transfer',
    'Faster Payments',
    'SWIFT Transfer',
    'Other',
  ];

  // Trust levels
  static const Map<String, double> trustLevelThresholds = {
    'Unproven': 0.0,
    'Very Low': 0.2,
    'Low': 0.4,
    'Average': 0.6,
    'High': 0.8,
    'Excellent': 0.95,
  };
}
