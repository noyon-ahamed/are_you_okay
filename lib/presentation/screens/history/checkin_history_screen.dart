import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../provider/checkin_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../routes/app_router.dart';

/// Check-in History Screen
/// Displays user's check-in history
class CheckinHistoryScreen extends ConsumerWidget {
  const CheckinHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(checkinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('চেক-ইন ইতিহাস'),
      ),
      body: checkinsAsync.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        success: (lastCheckIn) {
          final history = ref.watch(checkinHistoryProvider);
          if (history.isEmpty) {
            return const EmptyStateWidget(
              title: 'কোন চেক-ইন ইতিহাস নেই',
              description: 'আপনি এখনও কোন চেক-ইন করেননি।',
              icon: Icons.history,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final checkin = history[index];
              final dateTime = checkin.timestamp;
              final isToday = _isToday(dateTime);
              final isYesterday = _isYesterday(dateTime);

              String dateStr;
              if (isToday) {
                dateStr = 'আজ';
              } else if (isYesterday) {
                dateStr = 'গতকাল';
              } else {
                dateStr = DateFormat('d MMM yyyy', 'bn').format(dateTime);
              }

              final timeStr = DateFormat('h:mm a', 'bn').format(dateTime);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (checkin.latitude != null && checkin.longitude != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${checkin.latitude!.toStringAsFixed(4)}, ${checkin.longitude!.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getMethodColor(checkin.method)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getMethodText(checkin.method),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getMethodColor(checkin.method),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (message) => Center(
          child: Text('ত্রুটি: $message'),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  String _getMethodText(String method) {
    switch (method) {
      case 'button':
        return 'ম্যানুয়াল';
      case 'auto':
        return 'অটো';
      case 'reminder':
        return 'রিমাইন্ডার';
      default:
        return method;
    }
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'button':
        return AppColors.success;
      case 'auto':
        return AppColors.info;
      case 'reminder':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}
