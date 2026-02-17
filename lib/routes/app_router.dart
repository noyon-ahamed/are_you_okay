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
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/contacts/emergency_contacts_screen.dart';
import '../../presentation/screens/contacts/add_contact_screen.dart';
import '../../presentation/screens/sos/sos_screen.dart';
import '../../presentation/screens/history/checkin_history_screen.dart';

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
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String contacts = '/contacts';
  static const String addContact = '/contacts/add';
  static const String sos = '/sos';
  static const String history = '/history';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: ValueNotifier(authState),
    routes: [
      // ==================== Auth Flow ====================
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: Routes.register,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),

      // ==================== Main App ====================
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: Routes.aiChat,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AIChatScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
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
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.contacts,
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: Routes.addContact,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AddContactScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: Routes.sos,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SOSScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: Routes.history,
        builder: (context, state) => const CheckinHistoryScreen(),
      ),
    ],

    // ==================== Auth Guard ====================
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoading = authState is AuthLoading || authState is AuthInitial;
      final currentPath = state.uri.path;

      // Allow splash to load
      if (currentPath == Routes.splash) return null;

      // Allow onboarding regardless of auth state
      if (currentPath == Routes.onboarding) return null;

      // While loading auth state, stay on current page
      if (isLoading) return null;

      // Auth pages list
      final authPages = [
        Routes.login,
        Routes.register,
        Routes.forgotPassword,
      ];
      final isAuthPage = authPages.contains(currentPath);

      // If not authenticated and trying to access protected page
      if (!isAuthenticated && !isAuthPage) {
        return Routes.login;
      }

      // If authenticated and trying to access auth page
      if (isAuthenticated && isAuthPage) {
        return Routes.home;
      }

      return null;
    },
  );
});
