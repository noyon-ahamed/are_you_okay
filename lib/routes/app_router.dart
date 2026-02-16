import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/ai_chat/ai_chat_screen.dart';
import '../../presentation/screens/earthquake/earthquake_screen.dart';
import '../../presentation/screens/fake_call/fake_call_screen.dart';
// import '../../presentation/screens/onboarding/onboarding_screen.dart';

import '../../provider/auth_provider.dart';

class Routes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String aiChat = '/ai-chat';
  static const String earthquake = '/earthquake';
  static const String fakeCall = '/fake-call';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String contacts = '/contacts';
  static const String sos = '/sos';
  static const String history = '/history';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: ValueNotifier(authState), 
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.aiChat,
        builder: (context, state) => const AIChatScreen(),
      ),
      GoRoute(
        path: Routes.earthquake,
        builder: (context, state) => const EarthquakeScreen(),
      ),
      GoRoute(
        path: Routes.fakeCall,
        builder: (context, state) => const FakeCallScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        // TODO: Implement ProfileScreen
        builder: (context, state) => const Scaffold(body: Center(child: Text('Profile Screen'))),
      ),
      GoRoute(
        path: Routes.settings,
        // TODO: Implement SettingsScreen
        builder: (context, state) => const Scaffold(body: Center(child: Text('Settings Screen'))),
      ),
      GoRoute(
        path: Routes.contacts,
        // TODO: Implement ContactsScreen
        builder: (context, state) => const Scaffold(body: Center(child: Text('Contacts Screen'))),
      ),
      GoRoute(
        path: Routes.sos,
        // TODO: Implement SOSScreen - currently using placeholder or separate screen
         builder: (context, state) => const Scaffold(body: Center(child: Text('SOS Screen'))),
      ),
      GoRoute(
        path: Routes.history,
        // TODO: Implement HistoryScreen
        builder: (context, state) => const Scaffold(body: Center(child: Text('History Screen'))),
      ),
    ],
    redirect: (context, state) {
      // Handle redirection based on auth state if needed
      // For now, let individual screens handle navigation or use this for protection
      return null;
    },
  );
});
