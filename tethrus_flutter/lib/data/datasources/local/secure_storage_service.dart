import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  static const _mnemonicKey = 'tethrus_mnemonic';
  static const _privateKeyKey = 'tethrus_private_key';
  static const _pinKey = 'tethrus_pin';
  static const _nicknameKey = 'tethrus_nickname';
  static const _identityKey = 'tethrus_identity_created';
  static const _biometricsKey = 'tethrus_biometrics_enabled';

  Future<void> saveMnemonic(String mnemonic) async {
    await _storage.write(key: _mnemonicKey, value: mnemonic);
  }

  Future<String?> getMnemonic() async {
    return await _storage.read(key: _mnemonicKey);
  }

  Future<void> savePrivateKey(String privateKey) async {
    await _storage.write(key: _privateKeyKey, value: privateKey);
  }

  Future<String?> getPrivateKey() async {
    return await _storage.read(key: _privateKeyKey);
  }

  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> saveNickname(String nickname) async {
    await _storage.write(key: _nicknameKey, value: nickname);
  }

  Future<String?> getNickname() async {
    return await _storage.read(key: _nicknameKey);
  }

  Future<void> setIdentityCreated(bool created) async {
    await _storage.write(key: _identityKey, value: created.toString());
  }

  Future<bool> hasIdentity() async {
    final value = await _storage.read(key: _identityKey);
    return value == 'true';
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _storage.write(key: _biometricsKey, value: enabled.toString());
  }

  Future<bool> isBiometricsEnabled() async {
    final value = await _storage.read(key: _biometricsKey);
    return value == 'true';
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
