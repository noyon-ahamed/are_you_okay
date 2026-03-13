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
import '../../presentation/screens/settings/notification_settings_screen.dart';
import '../../presentation/screens/settings/about_app_screen.dart';
import '../../presentation/screens/settings/privacy_policy_screen.dart';
import '../../presentation/screens/contacts/emergency_contacts_screen.dart';
import '../../presentation/screens/contacts/add_contact_screen.dart';
import '../../presentation/screens/sos/sos_screen.dart';
import '../../presentation/screens/history/checkin_history_screen.dart';
import '../../presentation/screens/mood/mood_history_screen.dart';
import '../../presentation/screens/notification/notification_screen.dart';

import '../../provider/auth_provider.dart';
import '../../provider/splash_provider.dart';
import '../../services/shared_prefs_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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
  static const String fakeCallActive = '/fake-call-active';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String notificationSettings = '/settings/notifications';
  static const String aboutApp = '/settings/about';
  static const String privacyPolicy = '/settings/privacy';
  static const String contacts = '/contacts';
  static const String addContact = '/contacts/add';
  static const String sos = '/sos';
  static const String history = '/history';
  static const String moodHistory = '/mood-history';
  static const String notifications = '/notifications';
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<bool>(
      splashDisplayCompleteProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: notifier,
    routes: [
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
          restorationId: 'login_page',
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
          restorationId: 'register_page',
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          restorationId: 'forgot_password_page',
          child: const ForgotPasswordScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          restorationId: 'home_page',
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
          restorationId: 'ai_chat_page',
          child: const AIChatScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: Routes.earthquake,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'earthquake_page',
          child: EarthquakeScreen(),
        ),
      ),
      GoRoute(
        path: Routes.moodHistory,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'mood_history_page',
          child: MoodHistoryScreen(),
        ),
      ),
      GoRoute(
        path: Routes.fakeCall,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'fake_call_page',
          child: FakeCallScreen(),
        ),
      ),
      GoRoute(
        path: Routes.profile,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'profile_page',
          child: ProfileScreen(),
        ),
      ),
      GoRoute(
        path: Routes.editProfile,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'edit_profile_page',
          child: EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'settings_page',
          child: SettingsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.notificationSettings,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'notification_settings_page',
          child: NotificationSettingsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.aboutApp,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'about_app_page',
          child: AboutAppScreen(),
        ),
      ),
      GoRoute(
        path: Routes.privacyPolicy,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'privacy_policy_page',
          child: PrivacyPolicyScreen(),
        ),
      ),
      GoRoute(
        path: Routes.contacts,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'contacts_page',
          child: EmergencyContactsScreen(),
        ),
      ),
      GoRoute(
        path: Routes.addContact,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          restorationId: 'add_contact_page',
          child: const AddContactScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: Routes.sos,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          restorationId: 'sos_page',
          child: const SOSScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: Routes.history,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'history_page',
          child: CheckinHistoryScreen(),
        ),
      ),
      GoRoute(
        path: Routes.notifications,
        pageBuilder: (context, state) => const MaterialPage(
          restorationId: 'notifications_page',
          child: NotificationScreen(),
        ),
      ),
    ],
    redirect: (context, state) {
      final isSplashComplete = ref.read(splashDisplayCompleteProvider);
      final authState = ref.read(authProvider);
      final sharedPrefs = ref.read(sharedPrefsServiceProvider);
      final currentPath = state.uri.path;
      final isFirstLaunch = sharedPrefs.isFirstLaunch;

      if (!isSplashComplete) {
        return Routes.splash;
      }

      final isAuthenticated = authState is AuthAuthenticated;
      final isLoading = authState is AuthLoading || authState is AuthInitial;
      const restorableRoutes = <String>{
        Routes.home,
        Routes.aiChat,
        Routes.earthquake,
        Routes.fakeCall,
        Routes.profile,
        Routes.editProfile,
        Routes.settings,
        Routes.notificationSettings,
        Routes.aboutApp,
        Routes.privacyPolicy,
        Routes.contacts,
        Routes.addContact,
        Routes.sos,
        Routes.history,
        Routes.moodHistory,
        Routes.notifications,
      };

      if (currentPath == Routes.onboarding) {
        if (isAuthenticated) return Routes.home;
        return isFirstLaunch ? null : Routes.login;
      }

      final authPages = [
        Routes.login,
        Routes.register,
        Routes.forgotPassword,
      ];
      final isAuthPage = authPages.contains(currentPath);

      if (isLoading) {
        if (isAuthPage) return null;
        return Routes.login;
      }

      if (!isAuthenticated && isFirstLaunch) {
        return Routes.onboarding;
      }

      if (!isAuthenticated && !isAuthPage && currentPath != Routes.splash) {
        return Routes.login;
      }

      if (isAuthenticated && (isAuthPage || currentPath == Routes.splash)) {
        return sharedPrefs.lastRoute != null &&
                restorableRoutes.contains(sharedPrefs.lastRoute)
            ? sharedPrefs.lastRoute
            : Routes.home;
      }

      if (!isAuthenticated && currentPath == Routes.splash) {
        return isFirstLaunch ? Routes.onboarding : Routes.login;
      }

      if (isAuthenticated && restorableRoutes.contains(currentPath)) {
        sharedPrefs.setLastRoute(currentPath);
      }

      return null;
    },
  );
});
