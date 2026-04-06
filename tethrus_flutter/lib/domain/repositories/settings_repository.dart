import 'package:flutter/material.dart';

abstract class SettingsRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
  Future<String> getDefaultFiatCurrency();
  Future<void> setDefaultFiatCurrency(String currency);
  Future<int> getAutoLockTimeout();
  Future<void> setAutoLockTimeout(int minutes);
  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
  Future<String?> getProxyAddress();
  Future<void> setProxyAddress(String? address);
  Future<String> getLanguage();
  Future<void> setLanguage(String language);
}
