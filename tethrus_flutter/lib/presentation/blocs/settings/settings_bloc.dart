import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/settings_repository.dart';

// Events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

class SettingsThemeChanged extends SettingsEvent {
  final ThemeMode themeMode;
  const SettingsThemeChanged({required this.themeMode});
  @override
  List<Object?> get props => [themeMode];
}

class SettingsFiatCurrencyChanged extends SettingsEvent {
  final String currency;
  const SettingsFiatCurrencyChanged({required this.currency});
  @override
  List<Object?> get props => [currency];
}

class SettingsAutoLockChanged extends SettingsEvent {
  final int minutes;
  const SettingsAutoLockChanged({required this.minutes});
  @override
  List<Object?> get props => [minutes];
}

class SettingsNotificationsChanged extends SettingsEvent {
  final bool enabled;
  const SettingsNotificationsChanged({required this.enabled});
  @override
  List<Object?> get props => [enabled];
}

class SettingsLanguageChanged extends SettingsEvent {
  final String language;
  const SettingsLanguageChanged({required this.language});
  @override
  List<Object?> get props => [language];
}

// State
class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final String defaultFiatCurrency;
  final int autoLockTimeout;
  final bool notificationsEnabled;
  final String language;
  final String? proxyAddress;
  final bool isLoading;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.defaultFiatCurrency = 'USD',
    this.autoLockTimeout = 5,
    this.notificationsEnabled = true,
    this.language = 'en',
    this.proxyAddress,
    this.isLoading = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? defaultFiatCurrency,
    int? autoLockTimeout,
    bool? notificationsEnabled,
    String? language,
    String? proxyAddress,
    bool? isLoading,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      defaultFiatCurrency: defaultFiatCurrency ?? this.defaultFiatCurrency,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      proxyAddress: proxyAddress ?? this.proxyAddress,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        themeMode, defaultFiatCurrency, autoLockTimeout,
        notificationsEnabled, language, proxyAddress, isLoading,
      ];
}

// BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository settingsRepository;

  SettingsBloc({required this.settingsRepository})
      : super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsThemeChanged>(_onThemeChanged);
    on<SettingsFiatCurrencyChanged>(_onFiatCurrencyChanged);
    on<SettingsAutoLockChanged>(_onAutoLockChanged);
    on<SettingsNotificationsChanged>(_onNotificationsChanged);
    on<SettingsLanguageChanged>(_onLanguageChanged);
  }

  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final themeMode = await settingsRepository.getThemeMode();
      final fiat = await settingsRepository.getDefaultFiatCurrency();
      final autoLock = await settingsRepository.getAutoLockTimeout();
      final notifications = await settingsRepository.getNotificationsEnabled();
      final language = await settingsRepository.getLanguage();
      final proxy = await settingsRepository.getProxyAddress();

      emit(state.copyWith(
        themeMode: themeMode,
        defaultFiatCurrency: fiat,
        autoLockTimeout: autoLock,
        notificationsEnabled: notifications,
        language: language,
        proxyAddress: proxy,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onThemeChanged(
    SettingsThemeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await settingsRepository.setThemeMode(event.themeMode);
    emit(state.copyWith(themeMode: event.themeMode));
  }

  Future<void> _onFiatCurrencyChanged(
    SettingsFiatCurrencyChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await settingsRepository.setDefaultFiatCurrency(event.currency);
    emit(state.copyWith(defaultFiatCurrency: event.currency));
  }

  Future<void> _onAutoLockChanged(
    SettingsAutoLockChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await settingsRepository.setAutoLockTimeout(event.minutes);
    emit(state.copyWith(autoLockTimeout: event.minutes));
  }

  Future<void> _onNotificationsChanged(
    SettingsNotificationsChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await settingsRepository.setNotificationsEnabled(event.enabled);
    emit(state.copyWith(notificationsEnabled: event.enabled));
  }

  Future<void> _onLanguageChanged(
    SettingsLanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await settingsRepository.setLanguage(event.language);
    emit(state.copyWith(language: event.language));
  }
}
