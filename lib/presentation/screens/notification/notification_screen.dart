import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../services/api/notification_api_service.dart';
import '../../../../services/local_notification_history_service.dart';
import '../../../../services/notification_navigation_service.dart';
import '../../../../services/notification_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import 'package:intl/intl.dart';
import '../../../../provider/language_provider.dart';

// Create a Notifier for notifications for silent refresh
class NotificationsNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  NotificationsNotifier() : super(const AsyncLoading()) {
    _bootstrap();
  }

  Future<void>? _fetchInFlight;
  final LocalNotificationHistoryService _historyService =
      LocalNotificationHistoryService();

  Future<void> _bootstrap() async {
    final cachedNotifications = await _historyService.getMergedNotifications();
    if (!mounted) return;
    if (cachedNotifications.isNotEmpty) {
      state = AsyncData(cachedNotifications);
    }
    await fetch(silent: cachedNotifications.isNotEmpty);
  }

  Future<void> fetch({bool silent = true}) async {
    if (_fetchInFlight != null) {
      return _fetchInFlight!;
    }

    final future = _fetchNotifications(silent: silent);
    _fetchInFlight = future;
    try {
      await future;
    } finally {
      _fetchInFlight = null;
    }
  }

  Future<void> _fetchNotifications({required bool silent}) async {
    if (!silent || !state.hasValue) {
      state = const AsyncLoading();
    }
    try {
      final api = NotificationApiService();
      List<Map<String, dynamic>> remoteNotifications = <Map<String, dynamic>>[];
      var remoteFetchSucceeded = false;
      try {
        final latestCreatedAt =
            await _historyService.getLatestRemoteCreatedAt();
        final data = await api.getNotifications(
          latestCreatedAt: latestCreatedAt,
        );
        remoteNotifications = (data['notifications'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        await _historyService.cacheRemoteNotifications(remoteNotifications);
        await _historyService.setLatestRemoteCreatedAt(
          data['sync']?['latestCreatedAt']?.toString(),
        );
        remoteFetchSucceeded = true;
      } catch (_) {
        remoteNotifications = <Map<String, dynamic>>[];
      }

      final merged = await _historyService.getMergedNotifications();
      if (!mounted) return;
      if (merged.isNotEmpty || remoteFetchSucceeded) {
        state = AsyncData(merged);
      }
    } catch (e, st) {
      if (!mounted) return;
      if (!silent || !state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await LocalNotificationHistoryService().markAllAsRead();
      try {
        await NotificationApiService().markAllAsRead();
      } catch (_) {}
      fetch(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(Map<String, dynamic> notification) async {
    try {
      final id = notification['_id']?.toString() ?? '';
      if (notification['isLocal'] == true) {
        await LocalNotificationHistoryService().markAsRead(id);
      } else {
        await NotificationApiService().markAsRead(id);
      }
      fetch(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNotification(Map<String, dynamic> notification) async {
    try {
      final id = notification['_id']?.toString() ?? '';
      if (notification['isLocal'] == true) {
        await LocalNotificationHistoryService().deleteNotification(id);
        final localId = notification['notificationId'];
        if (localId is int) {
          await LocalNotificationService().cancelNotification(localId);
        }
      } else {
        await NotificationApiService().deleteNotification(id);
      }
      fetch(silent: true);
    } catch (e) {
      rethrow;
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<List<dynamic>>>(
        (ref) {
  return NotificationsNotifier();
});

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with RestorationMixin {
  final RestorableDouble _scrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController;

  @override
  String? get restorationId => 'notification_screen';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).fetch(silent: true);
    });
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_scrollOffset, 'scroll_offset');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollOffset.value);
      }
    });
  }

  @override
  void dispose() {
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: s.notifMarkRead,
            onPressed: () async {
              try {
                await ref.read(notificationsProvider.notifier).markAllAsRead();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${s.chErrorPrefix} $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: isDark
            ? AppDecorations.subtleGradientDark()
            : AppDecorations.subtleGradientLight(),
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return EmptyState(
                icon: Icons.notifications_off_outlined,
                title: s.notifEmpty,
                description: s.notifEmpty,
              );
            }

            return ListView.builder(
              key: const PageStorageKey('notifications_scroll'),
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif['isRead'] == true;
                final date =
                    DateTime.tryParse(notif['createdAt']?.toString() ?? '')
                        ?.toLocal();

                return Card(
                  elevation: 0,
                  color: isRead
                      ? (isDark ? AppColors.surfaceDark : AppColors.surface)
                      : (isDark
                          // ignore: deprecated_member_use
                          ? AppColors.primary.withOpacity(0.15)
                          // ignore: deprecated_member_use
                          : AppColors.primaryLight.withOpacity(0.3)),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(notif['type']),
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      s.isBangla
                          ? (notif['title'] ?? 'নোটিফিকেশন')
                          : (notif['title_en'] ??
                              notif['title'] ??
                              'Notification'),
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notif['body'] ?? '',
                          style: TextStyle(
                            fontFamily: 'HindSiliguri',
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        if (date != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('d MMM, yyyy • hh:mm a', 'en')
                                .format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () async {
                      if (!isRead) {
                        try {
                          await ref
                              .read(notificationsProvider.notifier)
                              .markAsRead(Map<String, dynamic>.from(notif));
                        } catch (e) {
                          // ignore
                        }
                      }
                      final payload = notif['payload']?.toString();
                      if (payload != null && payload.isNotEmpty) {
                        NotificationNavigationService.handlePayload(payload);
                      } else if (notif['type'] == 'reminder') {
                        NotificationNavigationService.handlePayload(
                          NotificationNavigationService.encodePayload(
                            NotificationNavigationService.payloadForReminder(
                              notificationId:
                                  notif['_id']?.toString() ?? 'notification',
                            ),
                          ),
                        );
                      }
                    },
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(s.contactsDeleteConfirm,
                              style:
                                  const TextStyle(fontFamily: 'HindSiliguri')),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'delete') {
                          try {
                            await ref
                                .read(notificationsProvider.notifier)
                                .deleteNotification(
                                    Map<String, dynamic>.from(notif));
                          } catch (e) {
                            // ignore
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const ShimmerList(itemCount: 8),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(s.moodHistoryError,
                    style: const TextStyle(
                        fontFamily: 'HindSiliguri', fontSize: 16)),
                TextButton(
                  onPressed: () => ref
                      .read(notificationsProvider.notifier)
                      .fetch(silent: false),
                  child: Text(s.retry,
                      style: const TextStyle(fontFamily: 'HindSiliguri')),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'alert':
        return Icons.warning_rounded;
      case 'reminder':
        return Icons.alarm;
      case 'info':
        return Icons.info_outline;
      case 'checkin':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_active_outlined;
    }
  }
}
