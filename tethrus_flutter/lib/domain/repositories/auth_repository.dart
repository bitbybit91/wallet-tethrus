abstract class AuthRepository {
  Future<bool> isAuthenticated();
  Future<bool> hasIdentity();
  Future<List<String>> generateMnemonic();
  Future<void> createIdentity({
    required List<String> mnemonic,
    required String nickname,
  });
  Future<void> restoreIdentity(List<String> mnemonic);
  Future<bool> verifyPin(String pin);
  Future<void> setPin(String pin);
  Future<bool> hasPin();
  Future<void> setBiometricsEnabled(bool enabled);
  Future<bool> isBiometricsEnabled();
  Future<String?> getNickname();
  Future<void> setNickname(String nickname);
  Future<void> logout();
  Future<void> deleteAccount();
}
