import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/phone_verification_screen.dart';
import '../screens/home/home_screen.dart';

import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/contacts/emergency_contacts_screen.dart';
import '../screens/contacts/add_contact_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/settings/language_settings_screen.dart';
import '../screens/history/checkin_history_screen.dart';
import '../screens/sos/sos_screen.dart';

// Route names
class Routes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String phoneVerification = '/phone-verification';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String contacts = '/contacts';
  static const String addContact = '/add-contact';
  static const String notificationSettings = '/notification-settings';
  static const String languageSettings = '/language-settings';
  static const String history = '/history';
  static const String sos = '/sos';
}

// Router Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),

      // Onboarding
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      // Login
      GoRoute(
        path: Routes.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),

      // Register
      GoRoute(
        path: Routes.register,
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      // Phone Verification
      GoRoute(
        path: Routes.phoneVerification,
        name: 'phone-verification',
        pageBuilder: (context, state) {
          final phone = state.extra as String? ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: PhoneVerificationScreen(phoneNumber: phone),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
      ),

      // Home
      GoRoute(
        path: Routes.home,
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),

      // Profile
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),

      // Edit Profile
      GoRoute(
        path: Routes.editProfile,
        name: 'edit-profile',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),

      // Settings
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),

      // Notification Settings
      GoRoute(
        path: Routes.notificationSettings,
        name: 'notification-settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const NotificationSettingsScreen(),
        ),
      ),

      // Language Settings
      GoRoute(
        path: Routes.languageSettings,
        name: 'language-settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LanguageSettingsScreen(),
        ),
      ),

      // Contacts
      GoRoute(
        path: Routes.contacts,
        name: 'contacts',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const EmergencyContactsScreen(),
        ),
      ),

      // Add Contact
      GoRoute(
        path: Routes.addContact,
        name: 'add-contact',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const AddContactScreen(),
        ),
      ),

      // History
      GoRoute(
        path: Routes.history,
        name: 'history',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const CheckinHistoryScreen(),
        ),
      ),

      // SOS
      GoRoute(
        path: Routes.sos,
        name: 'sos',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SOSScreen(),
        ),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(Routes.splash),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
});