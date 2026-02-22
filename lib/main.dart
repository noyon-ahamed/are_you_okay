import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'provider/settings_provider.dart';
import 'services/hive_service.dart';
import 'services/shared_prefs_service.dart';
import 'services/offline_sync_service.dart';
import 'services/background_service.dart';
import 'presentation/widgets/lifecycle_manager.dart';
import 'presentation/screens/fake_call/fake_call_active_screen.dart';

final ValueNotifier<Map<String, dynamic>?> globalActiveCallNotifier = ValueNotifier(null);
/// Track handled call IDs to avoid re-showing on app resume
final Set<String> _handledCallIds = {};

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

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Hive
  await Hive.initFlutter();
  
  // Create ProviderContainer
  final container = ProviderContainer();

  // Initialize Date formatting for Bengali
  await initializeDateFormatting('bn', null);

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

class AreYouOkayApp extends ConsumerStatefulWidget {
  const AreYouOkayApp({super.key});

  @override
  ConsumerState<AreYouOkayApp> createState() => _AreYouOkayAppState();
}

class _AreYouOkayAppState extends ConsumerState<AreYouOkayApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToCallKitEvents();
    _checkActiveCalls();
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
      
      // Skip if this call was already handled
      if (_handledCallIds.contains(callId)) {
        return;
      }

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

            // Mark as handled to prevent re-show on app resume
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
          // Clear handled call ID on end
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
      title: 'ভালো আছেন কি?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            ValueListenableBuilder<Map<String, dynamic>?>(
              valueListenable: globalActiveCallNotifier,
              builder: (context, activeCall, _) {
                if (activeCall == null) return const SizedBox.shrink();
                return FakeCallActiveScreen(
                  callerName: activeCall['callerName'] ?? 'Unknown',
                  callerNumber: activeCall['callerNumber'] ?? '',
                  callId: activeCall['callId'] ?? '',
                );
              },
            ),
          ],
        );
      },
    );
  }
}