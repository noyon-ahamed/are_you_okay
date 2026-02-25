import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../services/api/notification_api_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import 'package:intl/intl.dart';

// Create a Notifier for notifications for silent refresh
class NotificationsNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  NotificationsNotifier() : super(const AsyncLoading()) {
    fetch();
  }

  Future<void> fetch({bool silent = true}) async {
    if (!silent || !state.hasValue) {
      state = const AsyncLoading();
    }
    try {
      final api = NotificationApiService();
      final data = await api.getNotifications();
      state = AsyncData(data['notifications'] as List<dynamic>);
    } catch (e, st) {
      if (!silent || !state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await NotificationApiService().markAllAsRead();
      fetch(silent: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await NotificationApiService().markAsRead(id);
      fetch(silent: true);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteNotification(String id) async {
    try {
      await NotificationApiService().deleteNotification(id);
      fetch(silent: true);
    } catch (e) {
      rethrow;
    }
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<dynamic>>>((ref) {
  return NotificationsNotifier();
});

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Silently refresh on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).fetch(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('নোটিফিকেশন'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'সব পড়া হয়েছে',
            onPressed: () async {
              try {
                await ref.read(notificationsProvider.notifier).markAllAsRead();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ত্রুটি: $e')),
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
                title: 'কোনো নোটিফিকেশন নেই',
                description: 'আপনার সব নতুন নোটিফিকেশন এখানে দেখাবে',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif['isRead'] == true;
                final date = DateTime.tryParse(notif['createdAt']?.toString() ?? '')?.toLocal();

                return Card(
                  elevation: 0,
                  color: isRead 
                      ? (isDark ? AppColors.surfaceDark : AppColors.surface)
                      : (isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primaryLight.withOpacity(0.3)),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
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
                      notif['title'] ?? 'নোটিফিকেশন',
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
                            DateFormat('d MMM, yyyy • hh:mm a', 'en').format(date),
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
                          await ref.read(notificationsProvider.notifier).markAsRead(notif['_id']);
                        } catch (e) {
                          // ignore
                        }
                      }
                    },
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('মুছে ফেলুন', style: TextStyle(fontFamily: 'HindSiliguri')),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'delete') {
                          try {
                            await ref.read(notificationsProvider.notifier).deleteNotification(notif['_id']);
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
          loading: () => ShimmerList(itemCount: 8),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('নোটিফিকেশন লোড করতে ত্রুটি হয়েছে', style: TextStyle(fontFamily: 'HindSiliguri', fontSize: 16)),
                TextButton(
                  onPressed: () => ref.read(notificationsProvider.notifier).fetch(silent: false),
                  child: const Text('আবার চেষ্টা করুন', style: TextStyle(fontFamily: 'HindSiliguri')),
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
