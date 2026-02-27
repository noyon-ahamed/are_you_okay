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
import '../../presentation/screens/fake_call/fake_call_active_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/contacts/emergency_contacts_screen.dart';
import '../../presentation/screens/contacts/add_contact_screen.dart';
import '../../presentation/screens/sos/sos_screen.dart';
import '../../presentation/screens/history/checkin_history_screen.dart';
import '../../presentation/screens/mood/mood_history_screen.dart';
import '../../presentation/screens/notification/notification_screen.dart';

import '../../provider/auth_provider.dart';
import '../../provider/splash_provider.dart';

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
        path: Routes.moodHistory,
        builder: (context, state) => const MoodHistoryScreen(),
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
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const NotificationScreen(),
      ),
    ],

    // ==================== Auth Guard ====================
    redirect: (context, state) {
      final isSplashComplete = ref.read(splashDisplayCompleteProvider);
      final authState = ref.read(authProvider);

       // Wait for 2 second splash animation
      if (!isSplashComplete) {
        return Routes.splash;
      }
      
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoading = authState is AuthLoading || authState is AuthInitial;
      final currentPath = state.uri.path;

      // Allow onboarding regardless of auth state
      if (currentPath == Routes.onboarding) return null;

      // While loading auth state, stay on splash instead of hanging
      if (isLoading) return Routes.splash;

      // Auth pages list
      final authPages = [
        Routes.login,
        Routes.register,
        Routes.forgotPassword,
      ];
      final isAuthPage = authPages.contains(currentPath);

      // If not authenticated and trying to access protected page
      if (!isAuthenticated && !isAuthPage && currentPath != Routes.splash) {
        return Routes.login;
      }

      // If authenticated and trying to access auth page or splash
      if (isAuthenticated && (isAuthPage || currentPath == Routes.splash)) {
        return Routes.home;
      }
      
      // If unauthenticated but splash is complete, go to login
      if (!isAuthenticated && currentPath == Routes.splash) {
        return Routes.login;
      }

      return null;
    },
  );
});
