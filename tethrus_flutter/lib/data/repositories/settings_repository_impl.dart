import 'package:flutter/material.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local/preferences_service.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final PreferencesService preferences;

  SettingsRepositoryImpl({required this.preferences});

  @override
  Future<ThemeMode> getThemeMode() async {
    final mode = preferences.getThemeMode();
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      _ => 'dark',
    };
    await preferences.setThemeMode(modeStr);
  }

  @override
  Future<String> getDefaultFiatCurrency() async {
    return preferences.getDefaultFiatCurrency();
  }

  @override
  Future<void> setDefaultFiatCurrency(String currency) async {
    await preferences.setDefaultFiatCurrency(currency);
  }

  @override
  Future<int> getAutoLockTimeout() async {
    return preferences.getAutoLockTimeout();
  }

  @override
  Future<void> setAutoLockTimeout(int minutes) async {
    await preferences.setAutoLockTimeout(minutes);
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    return preferences.getNotificationsEnabled();
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await preferences.setNotificationsEnabled(enabled);
  }

  @override
  Future<String?> getProxyAddress() async {
    return preferences.getProxyAddress();
  }

  @override
  Future<void> setProxyAddress(String? address) async {
    await preferences.setProxyAddress(address);
  }

  @override
  Future<String> getLanguage() async {
    return preferences.getLanguage();
  }

  @override
  Future<void> setLanguage(String language) async {
    await preferences.setLanguage(language);
  }
}
