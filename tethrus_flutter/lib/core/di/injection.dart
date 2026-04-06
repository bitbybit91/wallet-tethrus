import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/local/secure_storage_service.dart';
import '../../data/datasources/local/preferences_service.dart';
import '../../data/datasources/remote/tron_api_service.dart';
import '../../data/datasources/remote/market_api_service.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../data/repositories/market_repository_impl.dart';
import '../../data/repositories/trade_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/repositories/market_repository.dart';
import '../../domain/repositories/trade_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/market/market_bloc.dart';
import '../../presentation/blocs/wallet/wallet_bloc.dart';
import '../../presentation/blocs/trade/trade_bloc.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../../presentation/blocs/settings/settings_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/crypto/wallet_crypto.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPrefs);
  getIt.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.tronGridApiUrl,
    connectTimeout: AppConstants.apiTimeout,
    receiveTimeout: AppConstants.apiTimeout,
  ));
  getIt.registerSingleton<Dio>(dio);

  // Services
  getIt.registerSingleton<SecureStorageService>(
    SecureStorageService(getIt<FlutterSecureStorage>()),
  );
  getIt.registerSingleton<PreferencesService>(
    PreferencesService(getIt<SharedPreferences>()),
  );
  getIt.registerSingleton<TronApiService>(
    TronApiService(getIt<Dio>()),
  );
  getIt.registerSingleton<MarketApiService>(
    MarketApiService(),
  );
  getIt.registerSingleton<WalletCrypto>(WalletCrypto());

  // Repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      secureStorage: getIt<SecureStorageService>(),
      preferences: getIt<PreferencesService>(),
      walletCrypto: getIt<WalletCrypto>(),
    ),
  );
  getIt.registerSingleton<WalletRepository>(
    WalletRepositoryImpl(
      tronApi: getIt<TronApiService>(),
      secureStorage: getIt<SecureStorageService>(),
      walletCrypto: getIt<WalletCrypto>(),
    ),
  );
  getIt.registerSingleton<MarketRepository>(
    MarketRepositoryImpl(
      marketApi: getIt<MarketApiService>(),
    ),
  );
  getIt.registerSingleton<TradeRepository>(
    TradeRepositoryImpl(
      marketApi: getIt<MarketApiService>(),
    ),
  );
  getIt.registerSingleton<ChatRepository>(
    ChatRepositoryImpl(),
  );
  getIt.registerSingleton<SettingsRepository>(
    SettingsRepositoryImpl(
      preferences: getIt<PreferencesService>(),
    ),
  );

  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerFactory<MarketBloc>(
    () => MarketBloc(marketRepository: getIt<MarketRepository>()),
  );
  getIt.registerFactory<WalletBloc>(
    () => WalletBloc(walletRepository: getIt<WalletRepository>()),
  );
  getIt.registerFactory<TradeBloc>(
    () => TradeBloc(tradeRepository: getIt<TradeRepository>()),
  );
  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(chatRepository: getIt<ChatRepository>()),
  );
  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(settingsRepository: getIt<SettingsRepository>()),
  );
}
