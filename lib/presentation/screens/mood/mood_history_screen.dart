import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../services/api/mood_api_service.dart';
import '../../../services/mood_local_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import '../../../provider/checkin_provider.dart';
import '../../../provider/language_provider.dart';
import '../../../core/localization/app_strings.dart';

// --- Providers --- //

final moodApiProvider = Provider((ref) => MoodApiService());

class MoodStatsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  MoodStatsNotifier(this._api) : super(const AsyncLoading()) {
    _bootstrap();
  }

  final MoodApiService _api;
  Future<void>? _fetchInFlight;

  Future<void> _bootstrap() async {
    final cached = await _api.getCachedStats();
    if (cached != null) {
      state = AsyncData(cached);
    }
    await fetch(silent: cached != null);
  }

  Future<void> fetch({bool silent = true}) async {
    if (_fetchInFlight != null) {
      return _fetchInFlight!;
    }

    final future = _fetchStats(silent: silent);
    _fetchInFlight = future;
    try {
      await future;
    } finally {
      _fetchInFlight = null;
    }
  }

  Future<void> _fetchStats({required bool silent}) async {
    if (!silent || !state.hasValue) {
      state = const AsyncLoading();
    }

    try {
      state = AsyncData(await _api.getStats(days: 30));
    } catch (e, st) {
      if (!silent || !state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }
}

class MoodHistoryNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  MoodHistoryNotifier(this._api) : super(const AsyncLoading()) {
    _bootstrap();
  }

  final MoodApiService _api;
  Future<void>? _fetchInFlight;

  Future<void> _bootstrap() async {
    final cached = await _api.getCachedHistory();
    final cachedHistory = _extractHistory(cached);
    if (cachedHistory.isNotEmpty) {
      state = AsyncData(cachedHistory);
    }
    await fetch(silent: cachedHistory.isNotEmpty);
  }

  Future<void> fetch({bool silent = true}) async {
    if (_fetchInFlight != null) {
      return _fetchInFlight!;
    }

    final future = _fetchHistory(silent: silent);
    _fetchInFlight = future;
    try {
      await future;
    } finally {
      _fetchInFlight = null;
    }
  }

  Future<void> _fetchHistory({required bool silent}) async {
    if (!silent || !state.hasValue) {
      state = const AsyncLoading();
    }

    try {
      final latestCreatedAt = await _api.getLatestHistoryCreatedAt();
      final result = await _api.getHistory(
        limit: 50,
        latestCreatedAt: latestCreatedAt,
      );
      state = AsyncData(_extractHistory(result));
    } catch (e, st) {
      if (!silent || !state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }

  List<dynamic> _extractHistory(Map<String, dynamic>? result) {
    if (result == null) return <dynamic>[];
    final historyData = result['moods'] ?? result['history'] ?? result['data'];
    if (historyData is List) {
      return historyData;
    }
    return <dynamic>[];
  }
}

final moodStatsProvider =
    StateNotifierProvider<MoodStatsNotifier, AsyncValue<Map<String, dynamic>>>(
        (ref) {
  return MoodStatsNotifier(ref.watch(moodApiProvider));
});

final moodHistoryProvider =
    StateNotifierProvider<MoodHistoryNotifier, AsyncValue<List<dynamic>>>(
        (ref) {
  return MoodHistoryNotifier(ref.watch(moodApiProvider));
});

// --- Screen --- //

class MoodHistoryScreen extends ConsumerStatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  ConsumerState<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends ConsumerState<MoodHistoryScreen>
    with RestorationMixin {
  final RestorableInt _filterDays = RestorableInt(0);
  final RestorableDouble _scrollOffset = RestorableDouble(0);
  late final ScrollController _scrollController;

  // Local cache for last loaded data
  List<dynamic>? _cachedHistory;
  Map<String, dynamic>? _cachedStats;

  @override
  String? get restorationId => 'mood_history_screen';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        _scrollOffset.value = _scrollController.offset;
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(moodStatsProvider.notifier).fetch(silent: true);
      ref.read(moodHistoryProvider.notifier).fetch(silent: true);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.moodHistory),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterDays.value = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 0, child: Text(s.moodFilterAll)),
              PopupMenuItem(value: 7, child: Text(s.moodFilter7)),
              PopupMenuItem(value: 14, child: Text(s.moodFilter14)),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        key: const PageStorageKey('mood_history_scroll'),
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Statistics Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _buildStatsSection(ref, isDark, context),
            ),
          ),

          // 2. Timeline Section
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: _buildTimelineSection(ref, isDark, context),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildStatsSection(WidgetRef ref, bool isDark, BuildContext context) {
    final statusData = ref.watch(checkinStatusProvider);
    final statsAsyncValue = ref.watch(moodStatsProvider);

    return statsAsyncValue.when(
      skipLoadingOnRefresh: true,
      data: (statsData) {
        _cachedStats = statsData; // Cache on success
        final s = ref.watch(stringsProvider);
        return _buildStatsWidget(statsData, statusData, isDark, context, s);
      },
      loading: () {
        final s = ref.watch(stringsProvider);
        // Show cached stats while loading
        if (_cachedStats != null) {
          return _buildStatsWidget(
              _cachedStats!, statusData, isDark, context, s);
        }
        return const _StatsShimmer();
      },
      error: (error, _) {
        final s = ref.watch(stringsProvider);
        // Show cached stats on error (offline)
        if (_cachedStats != null) {
          return _buildStatsWidget(
              _cachedStats!, statusData, isDark, context, s);
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.cardDecoration(context: context),
          child: Text(s.moodStatsError,
              style: const TextStyle(color: AppColors.error)),
        );
      },
    );
  }

  Widget _buildStatsWidget(
      Map<String, dynamic> statsData,
      CheckInStatusData statusData,
      bool isDark,
      BuildContext context,
      AppStrings s) {
    final stats = statsData['stats'];
    if (stats == null || stats['totalEntries'] == 0) {
      return const SizedBox.shrink();
    }

    final totalEntries = stats['totalEntries'] as int? ?? 0;
    final distribution = stats['distribution'] as Map<String, dynamic>? ?? {};

    String? mostFrequentMood;
    int maxCount = 0;
    distribution.forEach((key, value) {
      final count = (value as num).toInt();
      if (count > maxCount) {
        maxCount = count;
        mostFrequentMood = key;
      }
    });

    final currentStreak = statusData.streak;

    String freqEmoji = '😶';
    final backendKeys = ['happy', 'good', 'neutral', 'sad', 'anxious', 'angry'];
    if (mostFrequentMood != null) {
      final index = backendKeys.indexOf(mostFrequentMood!);
      if (index != -1 && index < AppConstants.moodEmojis.length) {
        freqEmoji = AppConstants.moodEmojis[index];
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.primaryGradientBg(borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.moodStat30Days,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'HindSiliguri',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                icon: null,
                customIcon:
                    Text(freqEmoji, style: const TextStyle(fontSize: 28)),
                label: s.moodStatMain,
              ),
              Container(
                width: 1,
                height: 40,
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStat(
                icon: Icons.local_fire_department,
                value: '$currentStreak',
                label: s.chStatStreak,
              ),
              Container(
                width: 1,
                height: 40,
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStat(
                icon: Icons.calendar_month,
                value: '$totalEntries',
                label: s.moodStatTotal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    IconData? icon,
    Widget? customIcon,
    String? value,
    required String label,
  }) {
    return Column(
      children: [
        if (customIcon != null)
          customIcon
        else if (icon != null)
          Icon(icon, color: Colors.white, size: 28),
        if (value != null) ...[
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
        ],
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontFamily: 'HindSiliguri',
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection(
      WidgetRef ref, bool isDark, BuildContext context) {
    final historyAsyncValue = ref.watch(moodHistoryProvider);

    return historyAsyncValue.when(
      skipLoadingOnRefresh: true,
      data: (allHistory) {
        final s = ref.watch(stringsProvider);
        _cachedHistory = allHistory; // Cache on success
        return _buildHistoryList(allHistory, isDark, context, s);
      },
      loading: () {
        final s = ref.watch(stringsProvider);
        // Show cached history while loading
        if (_cachedHistory != null) {
          return _buildHistoryList(_cachedHistory!, isDark, context, s);
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const _TimelineShimmer(),
            childCount: 5,
          ),
        );
      },
      error: (error, _) {
        final s = ref.watch(stringsProvider);
        // Show cached history on error (offline)
        if (_cachedHistory != null) {
          return _buildHistoryList(_cachedHistory!, isDark, context, s);
        }

        // Fallback to local pending moods
        final localMoods = ref.read(moodLocalServiceProvider).getPendingMoods();
        if (localMoods.isNotEmpty) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final s = ref.watch(stringsProvider);
                final moodData = localMoods[index];
                return _buildMoodItem(context, moodData, isDark, s);
              },
              childCount: localMoods.length,
            ),
          );
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.wifi_off,
              title: s.noInternet,
              description: s.earthquakeOfflineMessage,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(List<dynamic> allHistory, bool isDark,
      BuildContext context, AppStrings s) {
    List<dynamic> history = allHistory;
    if (_filterDays.value > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: _filterDays.value));
      history = allHistory.where((item) {
        if (item['timestamp'] != null) {
          final date = DateTime.tryParse(item['timestamp'].toString());
          if (date != null) return date.toLocal().isAfter(cutoff);
        }
        return true;
      }).toList();
    }

    if (history.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: EmptyState(
            icon: Icons.sentiment_neutral_rounded,
            title: s.moodEmptyHome,
            description: s.moodEmptyHomeDesc,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final s = ref.watch(stringsProvider);
          final moodData = history[index] as Map<String, dynamic>;
          return _buildMoodItem(context, moodData, isDark, s);
        },
        childCount: history.length,
      ),
    );
  }

  Widget _buildMoodItem(BuildContext context, Map<String, dynamic> moodData,
      bool isDark, AppStrings s) {
    final mood = moodData['mood'] as String? ?? 'Unknown';
    final note = moodData['note'] as String?;
    final timestampStr = moodData['timestamp'] as String?;

    DateTime? timestamp;
    if (timestampStr != null) {
      timestamp = DateTime.tryParse(timestampStr);
    }

    // Find the emoji and styling for the mood
    String emoji = '😶';
    Color moodColor = AppColors.primary;

    final moodKeys = ['happy', 'good', 'neutral', 'sad', 'anxious'];
    final index = moodKeys.indexOf(mood.toLowerCase());

    if (index != -1) {
      emoji = AppConstants.moodEmojis[index];
      // Assign subtle colors based on mood
      if (index == 0) {
        moodColor = Colors.green; // Happy
      } else if (index == 1)
        // ignore: curly_braces_in_flow_control_structures
        moodColor = Colors.lightGreen; // Good
      else if (index == 2)
        // ignore: curly_braces_in_flow_control_structures
        moodColor = Colors.blue; // Neutral
      else if (index == 3)
        // ignore: curly_braces_in_flow_control_structures
        moodColor = Colors.red; // Sad
      // ignore: curly_braces_in_flow_control_structures
      else if (index == 4) moodColor = Colors.orange; // Anxious
    }

    // Fallback if the user typed Bengali directly or mapping failed
    if (index == -1) {
      final labelIndex = AppConstants.moodLabels.indexOf(mood);
      if (labelIndex != -1) {
        emoji = AppConstants.moodEmojis[labelIndex];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecoration(context: context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji Circle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: moodColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      index != -1 ? s.moodLabels[index] : mood,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'HindSiliguri',
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        timeago.format(timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontFamily: 'HindSiliguri',
                        ),
                      ),
                  ],
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMMM, yyyy • hh:mm a', s.lang)
                        .format(timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary)
                          // ignore: deprecated_member_use
                          .withOpacity(0.6),
                      fontFamily: 'HindSiliguri',
                    ),
                  ),
                ],
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          // ignore: deprecated_member_use
                          ? Colors.white.withOpacity(0.05)
                          // ignore: deprecated_member_use
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            // ignore: deprecated_member_use
                            ? Colors.white.withOpacity(0.1)
                            // ignore: deprecated_member_use
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 16,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontFamily: 'HindSiliguri',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Shimmer Loadings --- //

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      height: 140,
      borderRadius: 20,
    );
  }
}

class _TimelineShimmer extends StatelessWidget {
  const _TimelineShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: ShimmerLoading(
        height: 100,
        borderRadius: 16,
      ),
    );
  }
}
