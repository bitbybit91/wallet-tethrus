import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static const _themeModeKey = 'theme_mode';
  static const _fiatCurrencyKey = 'default_fiat_currency';
  static const _autoLockKey = 'auto_lock_timeout';
  static const _notificationsKey = 'notifications_enabled';
  static const _proxyKey = 'proxy_address';
  static const _languageKey = 'language';
  static const _onboardingCompleteKey = 'onboarding_complete';

  String getThemeMode() => _prefs.getString(_themeModeKey) ?? 'dark';
  Future<void> setThemeMode(String mode) => _prefs.setString(_themeModeKey, mode);

  String getDefaultFiatCurrency() => _prefs.getString(_fiatCurrencyKey) ?? 'USD';
  Future<void> setDefaultFiatCurrency(String currency) =>
      _prefs.setString(_fiatCurrencyKey, currency);

  int getAutoLockTimeout() => _prefs.getInt(_autoLockKey) ?? 5;
  Future<void> setAutoLockTimeout(int minutes) =>
      _prefs.setInt(_autoLockKey, minutes);

  bool getNotificationsEnabled() => _prefs.getBool(_notificationsKey) ?? true;
  Future<void> setNotificationsEnabled(bool enabled) =>
      _prefs.setBool(_notificationsKey, enabled);

  String? getProxyAddress() => _prefs.getString(_proxyKey);
  Future<void> setProxyAddress(String? address) async {
    if (address != null) {
      await _prefs.setString(_proxyKey, address);
    } else {
      await _prefs.remove(_proxyKey);
    }
  }

  String getLanguage() => _prefs.getString(_languageKey) ?? 'en';
  Future<void> setLanguage(String language) =>
      _prefs.setString(_languageKey, language);

  bool isOnboardingComplete() => _prefs.getBool(_onboardingCompleteKey) ?? false;
  Future<void> setOnboardingComplete(bool complete) =>
      _prefs.setBool(_onboardingCompleteKey, complete);
}
