import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'provider/settings_provider.dart';
import 'services/hive_service.dart';
import 'services/shared_prefs_service.dart';
import 'services/offline_sync_service.dart';
import 'services/background_service.dart';
import 'presentation/widgets/lifecycle_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();
  
  // Create ProviderContainer
  final container = ProviderContainer();

  // Initialize Services via their providers
  await container.read(hiveServiceProvider).init();
  await container.read(sharedPrefsServiceProvider).init();
  
  // Initialize Offline Sync Service (depends on Ref)
  await container.read(offlineSyncServiceProvider).init();

  // Initialize Background Service
  await BackgroundService.initialize();
  await BackgroundService.registerPeriodicTask();

  // Initialize Mobile Ads
  await MobileAds.instance.initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: LifecycleManager(
        child: AreYouOkayApp(),
      ),
    ),
  );
}

class AreYouOkayApp extends ConsumerWidget {
  const AreYouOkayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ভালো আছেন কি?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}