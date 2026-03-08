import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'provider/settings_provider.dart';
import 'services/hive_service.dart';
import 'services/shared_prefs_service.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'presentation/widgets/lifecycle_manager.dart';
import 'presentation/screens/fake_call/fake_call_active_screen.dart';

final ValueNotifier<Map<String, dynamic>?> globalActiveCallNotifier =
    ValueNotifier(null);

final Set<String> _handledCallIds = {};

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  late HiveService hiveService;
  late SharedPrefsService sharedPrefsService;

  await Future.wait([
    dotenv.load(fileName: ".env").catchError((e) {
      debugPrint('dotenv load warning: $e');
    }),
    Hive.initFlutter().then((_) async {
      hiveService = HiveService();
      await hiveService.init();
    }),
    initializeDateFormatting('bn', null),
  ]);

  sharedPrefsService = SharedPrefsService();
  await sharedPrefsService.init();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Firebase initialization warning: $e');
    }

    await BackgroundService.initialize();
    await BackgroundService.registerPeriodicTask();

    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;

      if (notificationsEnabled) {
        // Use SharedPrefsService.lastCheckIn which reads the canonical 'last_checkin' int key
        // (same key that background_service.dart reads and home_screen.dart writes via setLastCheckIn)
        final lastCheckIn = sharedPrefsService.lastCheckIn;
        bool needsReminder = true;

        if (lastCheckIn != null &&
            DateTime.now().difference(lastCheckIn).inHours < 24) {
          needsReminder = false;
        }

        if (needsReminder) {
          final notifService = LocalNotificationService();
          await notifService.initialize(onNotificationTap: (_) {});
          await scheduleDailyReminders(notifService);
        }
      }
    } catch (e) {
      debugPrint('Error scheduling startup reminders: $e');
    }

    final bool isSimulator = Platform.isIOS &&
        Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
    if (!isSimulator) {
      MobileAds.instance.initialize();
    }
  });

  runApp(
    ProviderScope(
      overrides: [
        hiveServiceProvider.overrideWithValue(hiveService),
        sharedPrefsServiceProvider.overrideWithValue(sharedPrefsService),
      ],
      child: const LifecycleManager(
        child: AreYouOkayApp(),
      ),
    ),
  );
}

class AreYouOkayApp extends ConsumerStatefulWidget {
  const AreYouOkayApp({super.key});

  @override
  ConsumerState<AreYouOkayApp> createState() => _AreYouOkayAppState();
}

class _AreYouOkayAppState extends ConsumerState<AreYouOkayApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToCallKitEvents();
    _checkActiveCalls();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.notification?.title}');
      _handleFirebaseMessage(message);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkActiveCalls();
    }
  }

  Future<void> _checkActiveCalls() async {
    final calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List && calls.isNotEmpty) {
      final currentCall = calls.first;
      final callId = currentCall['id'] as String? ?? '';

      if (_handledCallIds.contains(callId)) return;

      final callerFullName = currentCall['nameCaller'] as String? ?? 'Unknown';
      final parts = callerFullName.split('\n');
      final name = parts.isNotEmpty ? parts[0] : 'Unknown';
      final number = parts.length > 1 ? parts.sublist(1).join('\n') : '';

      globalActiveCallNotifier.value = {
        'callerName': name,
        'callerNumber': number,
        'callId': callId,
      };
    } else {
      globalActiveCallNotifier.value = null;
    }
  }

  void _listenToCallKitEvents() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) return;

      switch (event.event) {
        case Event.actionCallAccept:
          debugPrint('Global CallKit Accept received');
          final body = event.body as Map<dynamic, dynamic>?;
          if (body != null) {
            final callerFullName = body['nameCaller'] as String? ?? 'Unknown';
            final parts = callerFullName.split('\n');
            final name = parts.isNotEmpty ? parts[0] : 'Unknown';
            final number = parts.length > 1 ? parts.sublist(1).join('\n') : '';
            final callId = body['id'] as String? ?? '';

            _handledCallIds.add(callId);

            globalActiveCallNotifier.value = {
              'callerName': name,
              'callerNumber': number,
              'callId': callId,
            };
          }
          break;

        case Event.actionCallEnded:
        case Event.actionCallDecline:
        case Event.actionCallTimeout:
          final body = event.body as Map<dynamic, dynamic>?;
          if (body != null) {
            _handledCallIds.remove(body['id'] as String? ?? '');
          }
          globalActiveCallNotifier.value = null;
          break;

        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Are You Okay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              if (child != null) child,
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: globalActiveCallNotifier,
                builder: (context, activeCall, _) {
                  if (activeCall == null) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: FakeCallActiveScreen(
                      callerName: activeCall['callerName'] ?? 'Unknown',
                      callerNumber: activeCall['callerNumber'] ?? '',
                      callId: activeCall['callId'] ?? '',
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init background warning: $e');
  }
  debugPrint("Handling a background message: ${message.messageId}");
  await _handleFirebaseMessage(message);
}

Future<void> _handleFirebaseMessage(RemoteMessage message) async {
  final data = message.data;
  final title = message.notification?.title ?? 'Alert';
  final body = message.notification?.body ?? '';

  final distanceKmStr = data['distanceKm'];
  bool isSeismicClose = false;
  if (distanceKmStr != null) {
    final distance = double.tryParse(distanceKmStr);
    if (distance != null && distance < 100) {
      isSeismicClose = true;
    }
  }

  final notifService = LocalNotificationService();
  await notifService.initialize(onNotificationTap: (_) {});

  if (data['isClose'] == '1' || isSeismicClose) {
    await notifService.showEmergencyAlert(
      title: title,
      body: body,
      payload: 'earthquake_alert',
      isSeismicClose: true,
    );
  } else {
    await notifService.showEmergencyAlert(
      title: title,
      body: body,
      payload: 'emergency_alert',
      isSeismicClose: false,
    );
  }
}
