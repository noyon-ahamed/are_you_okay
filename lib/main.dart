import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/routes/app_router.dart';
import 'services/hive_service.dart';
import 'services/admob_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/firebase/fcm_service.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for local storage
  await Hive.initFlutter();
  final hiveService = HiveService();
  await hiveService.init();

  // Initialize AdMob
  await AdMobService().initialize();

  // Initialize Local Notifications
  await LocalNotificationService().initialize(
    onNotificationTap: (payload) {
      // Handle notification tap
      debugPrint('Notification tapped with payload: $payload');
    },
  );

  // Initialize FCM
  await FCMService().initialize(
    onMessage: (message) {
      debugPrint('FCM Message: ${message.notification?.title}');
      // Show local notification
      LocalNotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
      );
    },
    onMessageOpenedApp: (message) {
      debugPrint('Notification opened: ${message.notification?.title}');
      // Navigate based on message data
    },
    onTokenRefresh: (token) {
      debugPrint('FCM Token: $token');
      // Save token to Firestore
    },
  );

  // Initialize Background Service
  await BackgroundService.initialize();
  await BackgroundService.registerCheckinMonitor();
  await BackgroundService.registerWellnessReminder();

  // Set preferred orientations (portrait only for mobile app)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Run the app
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('bn', 'BD'), // Bangla
        Locale('en', 'US'), // English
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('bn', 'BD'),
      startLocale: const Locale('bn', 'BD'),
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // App Info
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Localization
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Routing
      routerConfig: router,

      // Builder for responsive and safe area
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // Prevent font scaling
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}