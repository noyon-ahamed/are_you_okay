import 'dart:async';
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
import 'package:flutter_timezone/flutter_timezone.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'provider/language_provider.dart';
import 'provider/auth_provider.dart';
import 'provider/settings_provider.dart';
import 'services/api/auth_api_service.dart';
import 'services/hive_service.dart';
import 'services/local_notification_history_service.dart';
import 'services/shared_prefs_service.dart';
import 'services/earthquake_alarm_service.dart';
import 'services/notification_navigation_service.dart';
import 'services/notification_service.dart';
import 'services/notification_sync_service.dart';
import 'presentation/widgets/lifecycle_manager.dart';
import 'presentation/screens/fake_call/fake_call_active_screen.dart';
import 'services/auth/token_storage_service.dart';

final ValueNotifier<Map<String, dynamic>?> globalActiveCallNotifier =
    ValueNotifier(null);
const MethodChannel _appBridgeChannel = MethodChannel('com.areyouokay.app/app');

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
  await _primeInitialActiveCallState();

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
  bool _servicesBootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapNonCriticalServices();
    });
  }

  Future<void> _bootstrapNonCriticalServices() async {
    if (_servicesBootstrapped) return;
    _servicesBootstrapped = true;

    _listenToCallKitEvents();
    unawaited(_checkActiveCalls());

    await Future<void>.delayed(const Duration(milliseconds: 800));

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      _setupFirebaseMessaging();
      unawaited(_syncNotificationPreferences());
    } catch (e) {
      debugPrint('Firebase initialization warning: $e');
    }
    final bool isSimulator = Platform.isIOS &&
        Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
    if (!isSimulator) {
      unawaited(MobileAds.instance.initialize());
    }
  }

  Future<void> _syncNotificationPreferences() async {
    try {
      final authState = ref.read(authProvider);
      if (authState is! AuthAuthenticated) return;

      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? true;
      final timezone = await FlutterTimezone.getLocalTimezone();
      final language = ref.read(languageProvider);
      final earthquakeCountry = ref.read(settingsProvider).earthquakeCountry;

      await AuthApiService().updateNotificationPreferences(
        notificationEnabled: notificationsEnabled,
        smsAlerts: ref.read(settingsProvider).smsAlerts,
        wellnessReminders: ref.read(settingsProvider).wellnessReminders,
        emergencyAlerts: ref.read(settingsProvider).emergencyAlerts,
        reminderTimes: AppConstants.defaultReminderTimes,
        timezone: timezone,
        language: language,
        earthquakeCountry: earthquakeCountry,
      );
    } catch (e) {
      debugPrint('Notification preferences sync warning: $e');
    }
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.notification?.title}');
      _handleFirebaseMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleRemoteMessageTap(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleRemoteMessageTap(message);
      }
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
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        ref.read(authProvider.notifier).refreshProfile();
        unawaited(NotificationSyncService().syncMissedNotifications());
      }
    }
  }

  Future<void> _checkActiveCalls() async {
    final calls = await FlutterCallkitIncoming.activeCalls();
    final currentCall = _resolveActiveCall(calls, preferAccepted: true);

    if (currentCall != null) {
      final nextCallId = currentCall['callId']?.toString() ?? '';
      final currentCallId =
          globalActiveCallNotifier.value?['callId']?.toString() ?? '';

      if (currentCallId != nextCallId ||
          globalActiveCallNotifier.value == null) {
        globalActiveCallNotifier.value = currentCall;
      }
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
          unawaited(_bringAppToForeground());
          final activeCall = _resolveCallInfo(event.body) ??
              _resolveActiveCall(
                await FlutterCallkitIncoming.activeCalls(),
                preferAccepted: true,
              );
          if (activeCall != null) {
            final callId = activeCall['callId']?.toString() ?? '';
            if (callId.isNotEmpty) {
              unawaited(FlutterCallkitIncoming.setCallConnected(callId));
            }
            globalActiveCallNotifier.value = activeCall;
          } else {
            await _checkActiveCalls();
          }
          break;

        case Event.actionCallEnded:
        case Event.actionCallDecline:
        case Event.actionCallTimeout:
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
      restorationScopeId: 'app',
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

  Future<void> _bringAppToForeground() async {
    if (!Platform.isAndroid) return;

    try {
      await _appBridgeChannel.invokeMethod<bool>('bringToFront');
    } catch (e) {
      debugPrint('Bring to foreground failed: $e');
    }
  }
}

Future<void> _primeInitialActiveCallState() async {
  try {
    final calls = await FlutterCallkitIncoming.activeCalls();
    final activeCall = _resolveActiveCall(calls, preferAccepted: true);
    if (activeCall != null) {
      globalActiveCallNotifier.value = activeCall;
    }
  } catch (e) {
    debugPrint('Initial active call check failed: $e');
  }
}

Map<String, dynamic>? _resolveActiveCall(
  dynamic rawCalls, {
  bool preferAccepted = false,
}) {
  if (rawCalls is! List || rawCalls.isEmpty) return null;

  final parsedCalls = rawCalls
      .whereType<Map>()
      .map<Map<String, dynamic>?>((call) => _resolveCallInfo(call))
      .whereType<Map<String, dynamic>>()
      .toList();

  if (parsedCalls.isEmpty) return null;

  if (preferAccepted) {
    final acceptedCall = parsedCalls.cast<Map<String, dynamic>?>().firstWhere(
          (call) => call?['isAccepted'] == true,
          orElse: () => null,
        );
    if (acceptedCall != null) return acceptedCall;
  }

  return parsedCalls.first;
}

Map<String, dynamic>? _resolveCallInfo(dynamic rawCall) {
  if (rawCall is! Map) return null;

  final call = Map<String, dynamic>.from(rawCall);
  final callerFullName =
      call['nameCaller']?.toString() ?? call['handle']?.toString() ?? 'Unknown';
  final parts = callerFullName.split('\n');
  final fallbackNumber = call['handle']?.toString() ?? '';
  final name = parts.isNotEmpty && parts.first.trim().isNotEmpty
      ? parts.first.trim()
      : 'Unknown';
  final number = parts.length > 1
      ? parts.sublist(1).join('\n').trim()
      : fallbackNumber.trim();

  return {
    'callerName': name,
    'callerNumber': number,
    'callId': call['id']?.toString() ?? '',
    'isAccepted': _asBool(call['isAccepted']),
  };
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

int _localNotificationIdForData(Map<String, dynamic> data) {
  final rawId = data['eventId']?.toString() ??
      data['notificationId']?.toString() ??
      '${data['type'] ?? 'alert'}-${data['route'] ?? ''}';
  return rawId.hashCode & 0x7fffffff;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init background warning: $e');
  }

  // ✅ Auth guard: Skip processing if no user is logged in.
  // This prevents logged-out accounts from receiving notifications
  // meant for other users on the same device.
  final token = await TokenStorageService.getToken();
  if (token == null || token.isEmpty) {
    debugPrint('Background message skipped — no authenticated user.');
    return;
  }

  debugPrint("Handling a background message: ${message.messageId}");

  final data = message.data;
  final distanceKmStr = data['distanceKm'];
  bool isSeismicClose = data['isClose'] == '1';
  if (!isSeismicClose && distanceKmStr != null) {
    final distance = double.tryParse(distanceKmStr);
    if (distance != null && distance < 100) {
      isSeismicClose = true;
    }
  }

  if (isSeismicClose) {
    final title =
        message.notification?.title ?? data['title'] ?? 'Earthquake Alert';
    final body = message.notification?.body ?? data['body'] ?? '';
    final payload = NotificationNavigationService.encodePayload({
      'route': _routeForNotificationType(data),
      'action': _actionForNotificationType(data),
      'type': data['type'] ?? 'earthquake',
      'eventId': data['eventId'] ?? '',
      'source': 'push_background',
    });
    final localNotificationId = _localNotificationIdForData(data);

    await EarthquakeAlarmService().startCloseAlert(
      eventId: data['eventId']?.toString() ??
          'close-${localNotificationId.toString()}',
    );

    final notifService = LocalNotificationService();
    await notifService.initialize(
      onNotificationTap: (_) {},
    );
    await notifService.showEmergencyAlert(
      id: localNotificationId,
      title: title,
      body: body,
      payload: payload,
      isSeismicClose: true,
    );
  }

  await _saveFirebaseMessageToHistory(message);
}

Future<void> _handleFirebaseMessage(RemoteMessage message) async {
  // ✅ Auth guard: Skip processing if no user is logged in.
  // When multiple accounts share a device, the FCM token may still
  // deliver messages even after one account logs out. This check
  // ensures only the currently logged-in user sees notifications.
  final authToken = await TokenStorageService.getToken();
  if (authToken == null || authToken.isEmpty) {
    debugPrint('Foreground message skipped — no authenticated user.');
    return;
  }

  final data = message.data;
  final title = message.notification?.title ?? data['title'] ?? 'Alert';
  final body = message.notification?.body ?? data['body'] ?? '';

  // Skip if it's just a generic "Alert" with no body and no other info
  if (title == 'Alert' && body.isEmpty && data['type'] == null) {
    debugPrint('Skipping empty notification');
    return;
  }

  final distanceKmStr = data['distanceKm'];
  bool isSeismicClose = false;
  if (distanceKmStr != null) {
    final distance = double.tryParse(distanceKmStr);
    if (distance != null && distance < 100) {
      isSeismicClose = true;
    }
  }

  final notifService = LocalNotificationService();
  await notifService.initialize(
    onNotificationTap: NotificationNavigationService.handlePayload,
  );

  final payload = NotificationNavigationService.encodePayload({
    'route': _routeForNotificationType(data),
    'action': _actionForNotificationType(data),
    'type': data['type'] ?? 'alert',
    'eventId': data['eventId'] ?? '',
    'source': 'push',
  });
  final localNotificationId = _localNotificationIdForData(data);

  if (data['type'] == 'checkin_reminder' || data['type'] == 'reminder') {
    await notifService.showCheckinReminder(
      title: title,
      body: body,
      payload: payload,
    );
  } else if (data['isClose'] == '1' || isSeismicClose) {
    await EarthquakeAlarmService().startCloseAlert(
      eventId: data['eventId']?.toString() ??
          'close-${localNotificationId.toString()}',
    );
    await notifService.showEmergencyAlert(
      id: localNotificationId,
      title: title,
      body: body,
      payload: payload,
      isSeismicClose: true,
    );
  } else {
    await notifService.showNotification(
      id: localNotificationId,
      title: title,
      body: body,
      payload: payload,
      channelId: data['channelId']?.toString() ?? 'info_updates',
    );
  }

  await _saveFirebaseMessageToHistory(message, payloadOverride: payload);
}

Future<void> _saveFirebaseMessageToHistory(
  RemoteMessage message, {
  String? payloadOverride,
}) async {
  final data = message.data;
  final title = message.notification?.title ?? data['title'] ?? 'Alert';
  final body = message.notification?.body ?? data['body'] ?? '';

  // Skip history if completely empty
  if (title == 'Alert' && body.isEmpty && data['type'] == null) return;

  final payload = payloadOverride ??
      NotificationNavigationService.encodePayload({
        'route': _routeForNotificationType(data),
        'action': _actionForNotificationType(data),
        'type': data['type'] ?? 'alert',
        'source': 'push',
      });

  await LocalNotificationHistoryService().saveNotification({
    '_id': data['notificationId']?.toString() ??
        'push-${message.messageId ?? DateTime.now().millisecondsSinceEpoch}',
    'title': title,
    'title_en': title,
    'body': body,
    'type': data['type'] ?? 'alert',
    'payload': payload,
    'createdAt': DateTime.now().toIso8601String(),
    'source': 'push',
  });
}

String _routeForNotificationType(Map<String, dynamic> data) {
  final explicitRoute = data['route']?.toString();
  if (explicitRoute != null && explicitRoute.isNotEmpty) {
    return explicitRoute;
  }

  final type = data['type']?.toString();
  if (type == 'checkin_reminder' || type == 'reminder') {
    return Routes.home;
  }
  if (type == 'earthquake') {
    return Routes.earthquake;
  }
  return Routes.notifications;
}

String _actionForNotificationType(Map<String, dynamic> data) {
  final explicitAction = data['action']?.toString();
  if (explicitAction != null && explicitAction.isNotEmpty) {
    return explicitAction;
  }

  final type = data['type']?.toString();
  if (type == 'checkin_reminder' || type == 'reminder') {
    return 'open_checkin';
  }
  return '';
}

void _handleRemoteMessageTap(RemoteMessage message) {
  final data = message.data;
  final payload = NotificationNavigationService.encodePayload({
    'route': _routeForNotificationType(data),
    'action': _actionForNotificationType(data),
    'type': data['type'] ?? 'alert',
    'source': 'push',
  });
  NotificationNavigationService.handlePayload(payload);
}
