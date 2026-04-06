import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/screens/onboarding/splash_screen.dart';
import '../../presentation/screens/onboarding/welcome_screen.dart';
import '../../presentation/screens/onboarding/create_identity_screen.dart';
import '../../presentation/screens/onboarding/verify_mnemonic_screen.dart';
import '../../presentation/screens/onboarding/set_pin_screen.dart';
import '../../presentation/screens/market/market_screen.dart';
import '../../presentation/screens/market/offer_detail_screen.dart';
import '../../presentation/screens/market/create_offer_screen.dart';
import '../../presentation/screens/trade/trade_screen.dart';
import '../../presentation/screens/trade/trade_chat_screen.dart';
import '../../presentation/screens/trade/trade_feedback_screen.dart';
import '../../presentation/screens/wallet/wallet_screen.dart';
import '../../presentation/screens/wallet/send_screen.dart';
import '../../presentation/screens/wallet/receive_screen.dart';
import '../../presentation/screens/chat/messages_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/settings/profile_screen.dart';
import '../../presentation/screens/settings/security_screen.dart';
import '../../presentation/screens/settings/about_screen.dart';
import '../../presentation/widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/create-identity',
      builder: (context, state) => const CreateIdentityScreen(),
    ),
    GoRoute(
      path: '/verify-mnemonic',
      builder: (context, state) {
        final mnemonic = state.extra as List<String>? ?? [];
        return VerifyMnemonicScreen(mnemonicWords: mnemonic);
      },
    ),
    GoRoute(
      path: '/set-pin',
      builder: (context, state) => const SetPinScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/market',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MarketScreen(),
          ),
          routes: [
            GoRoute(
              path: 'offer/:offerId',
              builder: (context, state) => OfferDetailScreen(
                offerId: state.pathParameters['offerId'] ?? '',
              ),
            ),
            GoRoute(
              path: 'create-offer',
              builder: (context, state) => const CreateOfferScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/trades',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TradeScreen(),
          ),
          routes: [
            GoRoute(
              path: ':tradeId/chat',
              builder: (context, state) => TradeChatScreen(
                tradeId: state.pathParameters['tradeId'] ?? '',
              ),
            ),
            GoRoute(
              path: ':tradeId/feedback',
              builder: (context, state) => TradeFeedbackScreen(
                tradeId: state.pathParameters['tradeId'] ?? '',
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/wallet',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WalletScreen(),
          ),
          routes: [
            GoRoute(
              path: 'send',
              builder: (context, state) => const SendScreen(),
            ),
            GoRoute(
              path: 'receive',
              builder: (context, state) => const ReceiveScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/messages',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MessagesScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: 'security',
              builder: (context, state) => const SecurityScreen(),
            ),
            GoRoute(
              path: 'about',
              builder: (context, state) => const AboutScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isOnboarding = state.matchedLocation == '/splash' ||
        state.matchedLocation == '/welcome' ||
        state.matchedLocation == '/create-identity' ||
        state.matchedLocation.startsWith('/verify-mnemonic') ||
        state.matchedLocation == '/set-pin';

    if (authState is AuthUnauthenticated && !isOnboarding) {
      return '/welcome';
    }

    return null;
  },
);
