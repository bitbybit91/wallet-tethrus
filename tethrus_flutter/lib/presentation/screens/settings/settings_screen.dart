import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/settings/settings_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(const SettingsLoadRequested());
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'This action is irreversible. Your wallet, identity, and all data will be permanently deleted. Make sure you have backed up your recovery phrase.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildProfileSection(),
              const SizedBox(height: 16),
              _buildSectionHeader('Preferences'),
              _buildThemeToggle(state),
              _buildCurrencyDropdown(state),
              _buildNotificationToggle(state),
              const SizedBox(height: 16),
              _buildSectionHeader('Security & Privacy'),
              _buildNavigationTile(
                icon: Icons.security,
                title: 'Security',
                subtitle: 'PIN, biometrics, backup',
                onTap: () => context.go('/settings/security'),
              ),
              _buildProxyTile(state),
              _buildAutoLockDropdown(state),
              const SizedBox(height: 16),
              _buildSectionHeader('General'),
              _buildLanguageTile(state),
              _buildNavigationTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Version, licenses, links',
                onTap: () => context.go('/settings/about'),
              ),
              const SizedBox(height: 24),
              _buildDeleteAccount(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final nickname = authState is AuthAuthenticated
            ? authState.nickname
            : 'Anonymous';

        return GestureDetector(
          onTap: () => context.go('/settings/profile'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      nickname.isNotEmpty
                          ? nickname[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View profile',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeToggle(SettingsState state) {
    final isDark = state.themeMode == ThemeMode.dark;
    return _buildSettingsTile(
      icon: isDark ? Icons.dark_mode : Icons.light_mode,
      title: 'Theme',
      trailing: Switch(
        value: isDark,
        activeColor: AppColors.primary,
        onChanged: (value) {
          context.read<SettingsBloc>().add(SettingsThemeChanged(
                themeMode: value ? ThemeMode.dark : ThemeMode.light,
              ));
        },
      ),
    );
  }

  Widget _buildCurrencyDropdown(SettingsState state) {
    const currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'RUB', 'BRL', 'INR'];
    return _buildSettingsTile(
      icon: Icons.attach_money,
      title: 'Default Currency',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currencies.contains(state.defaultFiatCurrency)
                ? state.defaultFiatCurrency
                : currencies.first,
            dropdownColor: AppColors.darkSurface,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            icon: const Icon(Icons.expand_more,
                size: 18, color: AppColors.textSecondary),
            items: currencies.map((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(
                    SettingsFiatCurrencyChanged(currency: value));
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(SettingsState state) {
    return _buildSettingsTile(
      icon: Icons.notifications_outlined,
      title: 'Notifications',
      trailing: Switch(
        value: state.notificationsEnabled,
        activeColor: AppColors.primary,
        onChanged: (value) {
          context.read<SettingsBloc>().add(
              SettingsNotificationsChanged(enabled: value));
        },
      ),
    );
  }

  Widget _buildProxyTile(SettingsState state) {
    return _buildSettingsTile(
      icon: Icons.shield_outlined,
      title: 'Proxy / Tor Configuration',
      subtitle: state.proxyAddress ?? 'Not configured',
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: () => _showProxyDialog(state),
    );
  }

  void _showProxyDialog(SettingsState state) {
    final controller =
        TextEditingController(text: state.proxyAddress ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Proxy / Tor',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'socks5://127.0.0.1:9050',
            hintStyle: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.darkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final value = controller.text.trim();
              context.read<SettingsBloc>().add(
                SettingsProxyChanged(
                  address: value.isEmpty ? null : value,
                ),
              );
              Navigator.pop(ctx);
            },
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoLockDropdown(SettingsState state) {
    final options = <int, String>{
      1: '1 min',
      5: '5 min',
      15: '15 min',
      30: '30 min',
      60: '1 hour',
    };

    return _buildSettingsTile(
      icon: Icons.lock_clock,
      title: 'Auto-lock Timeout',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: options.containsKey(state.autoLockTimeout)
                ? state.autoLockTimeout
                : 5,
            dropdownColor: AppColors.darkSurface,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            icon: const Icon(Icons.expand_more,
                size: 18, color: AppColors.textSecondary),
            items: options.entries.map((e) {
              return DropdownMenuItem(value: e.key, child: Text(e.value));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(
                    SettingsAutoLockChanged(minutes: value));
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(SettingsState state) {
    return _buildSettingsTile(
      icon: Icons.language,
      title: 'Language',
      subtitle: _languageLabel(state.language),
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: () => _showLanguageSheet(state),
    );
  }

  String _languageLabel(String code) {
    const labels = {
      'en': 'English',
      'es': 'Español',
      'pt': 'Português',
      'ru': 'Русский',
      'zh': '中文',
      'ja': '日本語',
    };
    return labels[code] ?? code;
  }

  void _showLanguageSheet(SettingsState state) {
    const languages = {
      'en': 'English',
      'es': 'Español',
      'pt': 'Português',
      'ru': 'Русский',
      'zh': '中文',
      'ja': '日本語',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Language',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            ...languages.entries.map((e) {
              final isSelected = e.key == state.language;
              return ListTile(
                title: Text(
                  e.value,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  context.read<SettingsBloc>().add(
                      SettingsLanguageChanged(language: e.key));
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return _buildSettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccount() {
    return GestureDetector(
      onTap: _showDeleteAccountDialog,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_forever, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
