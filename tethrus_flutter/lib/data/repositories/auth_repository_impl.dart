import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/secure_storage_service.dart';
import '../datasources/local/preferences_service.dart';
import '../../core/crypto/wallet_crypto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SecureStorageService secureStorage;
  final PreferencesService preferences;
  final WalletCrypto walletCrypto;

  AuthRepositoryImpl({
    required this.secureStorage,
    required this.preferences,
    required this.walletCrypto,
  });

  @override
  Future<bool> isAuthenticated() async {
    return await secureStorage.hasIdentity() && preferences.isOnboardingComplete();
  }

  @override
  Future<bool> hasIdentity() async {
    return await secureStorage.hasIdentity();
  }

  @override
  Future<List<String>> generateMnemonic() async {
    return walletCrypto.generateMnemonic();
  }

  @override
  Future<void> createIdentity({
    required List<String> mnemonic,
    required String nickname,
  }) async {
    await secureStorage.saveMnemonic(mnemonic.join(' '));
    await secureStorage.saveNickname(nickname);
    await secureStorage.setIdentityCreated(true);

    final seed = walletCrypto.mnemonicToSeed(mnemonic);
    final privateKey = walletCrypto.derivePrivateKey(seed);
    await secureStorage.savePrivateKey(privateKey);
  }

  @override
  Future<void> restoreIdentity(List<String> mnemonic) async {
    if (!walletCrypto.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic phrase');
    }
    await secureStorage.saveMnemonic(mnemonic.join(' '));
    await secureStorage.setIdentityCreated(true);

    final seed = walletCrypto.mnemonicToSeed(mnemonic);
    final privateKey = walletCrypto.derivePrivateKey(seed);
    await secureStorage.savePrivateKey(privateKey);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final storedPin = await secureStorage.getPin();
    return storedPin == pin;
  }

  @override
  Future<void> setPin(String pin) async {
    await secureStorage.savePin(pin);
    await preferences.setOnboardingComplete(true);
  }

  @override
  Future<bool> hasPin() async {
    return await secureStorage.hasPin();
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    await secureStorage.setBiometricsEnabled(enabled);
  }

  @override
  Future<bool> isBiometricsEnabled() async {
    return await secureStorage.isBiometricsEnabled();
  }

  @override
  Future<String?> getNickname() async {
    return await secureStorage.getNickname();
  }

  @override
  Future<void> setNickname(String nickname) async {
    await secureStorage.saveNickname(nickname);
  }

  @override
  Future<void> logout() async {
    // Keep identity but clear session
  }

  @override
  Future<void> deleteAccount() async {
    await secureStorage.deleteAll();
    await preferences.setOnboardingComplete(false);
  }
}
