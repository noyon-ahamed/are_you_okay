import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../provider/checkin_provider.dart';
import '../../../provider/language_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../widgets/empty_state.dart';

class CheckinHistoryScreen extends ConsumerStatefulWidget {
  const CheckinHistoryScreen({super.key});

  @override
  ConsumerState<CheckinHistoryScreen> createState() =>
      _CheckinHistoryScreenState();
}

class _CheckinHistoryScreenState extends ConsumerState<CheckinHistoryScreen>
    with RestorationMixin {
  final RestorableInt _filterDays = RestorableInt(0);
  final RestorableDouble _scrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController;

  @override
  String? get restorationId => 'checkin_history_screen';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkinHistoryFromBackendProvider.notifier).fetch(silent: true);
    });
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_filterDays, 'filter_days');
    registerForRestoration(_scrollOffset, 'scroll_offset');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollOffset.value);
      }
    });
  }

  @override
  void dispose() {
    _filterDays.dispose();
    _scrollOffset.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(checkinHistoryFromBackendProvider);
    final statusData = ref.watch(checkinStatusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.chHistoryTitle),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterDays.value = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 0,
                  child: Text(s.chFilterAll,
                      style: const TextStyle(fontFamily: 'HindSiliguri'))),
              PopupMenuItem(
                  value: 7,
                  child: Text(s.chFilter7,
                      style: const TextStyle(fontFamily: 'HindSiliguri'))),
              PopupMenuItem(
                  value: 14,
                  child: Text(s.chFilter14,
                      style: const TextStyle(fontFamily: 'HindSiliguri'))),
            ],
          ),
        ],
      ),
      body: historyAsync.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('${s.chErrorPrefix} $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(checkinHistoryFromBackendProvider.notifier)
                    .fetch(silent: false),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
        data: (checkins) {
          List<Map<String, dynamic>> filtered = checkins;
          if (_filterDays.value > 0) {
            final cutoff =
                DateTime.now().subtract(Duration(days: _filterDays.value));
            filtered = checkins.where((c) {
              final timestamp = _parseTimestamp(c);
              return timestamp != null && timestamp.isAfter(cutoff);
            }).toList();
          }

          if (filtered.isEmpty) {
            return EmptyState(
              icon: Icons.history_rounded,
              title: s.chEmptyTitle,
              description: s.chEmptyDesc,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(checkinHistoryFromBackendProvider.notifier)
                  .fetch(silent: true);
            },
            child: _buildHistoryList(
                context, filtered, isDark, statusData.streak, s),
          );
        },
      ),
    );
  }

  DateTime? _parseTimestamp(Map<String, dynamic> checkin) {
    final ts =
        checkin['checkInTime'] ?? checkin['timestamp'] ?? checkin['createdAt'];
    if (ts == null) return null;
    return DateTime.tryParse(ts.toString())?.toLocal();
  }

  Widget _buildHistoryList(
      BuildContext context,
      List<Map<String, dynamic>> checkins,
      bool isDark,
      int streak,
      AppStrings s) {
    // Group by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final checkin in checkins) {
      final ts = _parseTimestamp(checkin);
      if (ts == null) continue;
      final dateKey = DateFormat('yyyy-MM-dd').format(ts);
      grouped.putIfAbsent(dateKey, () => []).add(checkin);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return CustomScrollView(
      key: const PageStorageKey('checkin_history_scroll'),
      controller: _scrollController,
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        // Stats header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: _buildStatsHeader(context, checkins, streak, isDark, s),
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
                              // ignore: deprecated_member_use
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDateHeader(date, s),
                              style: const TextStyle(
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
                        _buildCheckinItem(context, checkin, isDark, s)),
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

  Widget _buildStatsHeader(
      BuildContext context,
      List<Map<String, dynamic>> checkins,
      int streak,
      bool isDark,
      AppStrings s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.primaryGradientBg(borderRadius: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            icon: Icons.check_circle,
            value: '${checkins.length}',
            label: s.chStatTotal,
          ),
          Container(
            width: 1,
            height: 40,
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStat(
            icon: Icons.local_fire_department,
            value: '$streak',
            label: s.chStatStreak,
          ),
          Container(
            width: 1,
            height: 40,
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStat(
            icon: Icons.today,
            value: _todayCount(checkins).toString(),
            label: s.chStatToday,
          ),
        ],
      ),
    );
  }

  int _todayCount(List<Map<String, dynamic>> checkins) {
    final today = DateTime.now();
    return checkins.where((c) {
      final ts = _parseTimestamp(c);
      return ts != null &&
          ts.year == today.year &&
          ts.month == today.month &&
          ts.day == today.day;
    }).length;
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
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontFamily: 'HindSiliguri',
          ),
        ),
      ],
    );
  }

  Widget _buildCheckinItem(BuildContext context, Map<String, dynamic> checkin,
      bool isDark, AppStrings s) {
    final ts = _parseTimestamp(checkin);
    final time = ts != null ? DateFormat('hh:mm a').format(ts) : '--:--';
    final status = checkin['status']?.toString() ?? 'safe';
    final notes = checkin['notes']?.toString() ?? '';
    final location = checkin['location'] as Map<String, dynamic>?;
    final hasLocation = location != null &&
        (location['latitude'] != null || location['address'] != null);

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
                  // ignore: deprecated_member_use
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  status == 'safe' ? s.chStatusSafe : status,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontFamily: 'HindSiliguri',
                  ),
                ),
              ],
            ),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                notes,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const Spacer(),
          // Location indicator
          if (hasLocation)
            Icon(
              Icons.location_on,
              size: 16,
              // ignore: deprecated_member_use
              color: AppColors.success.withOpacity(0.6),
            ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date, AppStrings s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return s.chDateToday;
    if (dateOnly == today.subtract(const Duration(days: 1))) {
      return s.chDateYesterday;
    }
    return DateFormat('d MMMM, yyyy', s.isBangla ? 'bn' : 'en').format(date);
  }
}
