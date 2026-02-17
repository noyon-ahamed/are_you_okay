import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../model/checkin_model.dart';
import '../../../provider/checkin_provider.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';

class CheckinHistoryScreen extends ConsumerWidget {
  const CheckinHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkins = ref.watch(checkinHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('চেক-ইন ইতিহাস'),
        actions: [
          if (checkins.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () {
                // TODO: Calendar view
              },
            ),
        ],
      ),
      body: checkins.isEmpty
          ? const EmptyState(
              icon: Icons.history_rounded,
              title: 'এখনো কোনো চেক-ইন নেই',
              description: 'আপনার প্রথম চেক-ইন করুন\nইতিহাস এখানে দেখা যাবে',
            )
          : _buildHistoryList(context, checkins, isDark),
    );
  }



  Widget _buildHistoryList(
      BuildContext context, List<CheckInModel> checkins, bool isDark) {
    // Group by date
    final grouped = <String, List<CheckInModel>>{};
    for (final checkin in checkins) {
      final dateKey = DateFormat('yyyy-MM-dd').format(checkin.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(checkin);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Streak calculation
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < sortedKeys.length; i++) {
      final date = DateTime.parse(sortedKeys[i]);
      final diff = today.difference(date).inDays;
      if (diff == i || (i == 0 && diff <= 1)) {
        streak++;
      } else {
        break;
      }
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Stats header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: _buildStatsHeader(context, checkins, streak, isDark),
          ),
        ),
        
        // Timeline list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final dateKey = sortedKeys[index];
              final dateCheckins = grouped[dateKey]!;
              final date = DateTime.parse(dateKey);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDateHeader(date),
                              style: TextStyle(
                                fontFamily: 'HindSiliguri',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Check-in items
                    ...dateCheckins.map((checkin) =>
                        _buildCheckinItem(context, checkin, isDark)),
                  ],
                ),
              );
            },
            childCount: sortedKeys.length,
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildStatsHeader(BuildContext context, List<CheckInModel> checkins,
      int streak, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.primaryGradientBg(borderRadius: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            icon: Icons.check_circle,
            value: '${checkins.length}',
            label: 'মোট',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStat(
            icon: Icons.local_fire_department,
            value: '$streak',
            label: 'স্ট্রিক 🔥',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStat(
            icon: Icons.today,
            value: _todayCount(checkins).toString(),
            label: 'আজ',
          ),
        ],
      ),
    );
  }

  int _todayCount(List<CheckInModel> checkins) {
    final today = DateTime.now();
    return checkins.where((c) =>
        c.timestamp.year == today.year &&
        c.timestamp.month == today.month &&
        c.timestamp.day == today.day).length;
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'HindSiliguri',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontFamily: 'HindSiliguri',
          ),
        ),
      ],
    );
  }

  Widget _buildCheckinItem(
      BuildContext context, CheckInModel checkin, bool isDark) {
    final time = DateFormat('hh:mm a').format(checkin.timestamp);
    final methodIcon = checkin.method == 'button'
        ? Icons.touch_app
        : checkin.method == 'shake'
            ? Icons.vibration
            : Icons.timer;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.cardDecoration(context: context),
      child: Row(
        children: [
          // Timeline dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Time
          Text(
            time,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          // Method
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(methodIcon, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  _methodLabel(checkin.method),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontFamily: 'HindSiliguri',
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Location indicator
          if (checkin.latitude != null && checkin.longitude != null)
            Icon(
              Icons.location_on,
              size: 16,
              color: AppColors.success.withOpacity(0.6),
            ),
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'button':
        return 'বাটন';
      case 'shake':
        return 'শেইক';
      case 'auto':
        return 'অটো';
      default:
        return method;
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'আজ';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'গতকাল';
    return DateFormat('d MMMM, yyyy', 'bn').format(date);
  }
}
