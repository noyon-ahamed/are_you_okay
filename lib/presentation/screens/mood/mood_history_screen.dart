import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../services/api/mood_api_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/empty_state.dart';
import '../../../provider/checkin_provider.dart';

// --- Providers --- //

final moodApiProvider = Provider((ref) => MoodApiService());

final moodStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return await ref.watch(moodApiProvider).getStats(days: 30);
});

final moodHistoryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final result = await ref.watch(moodApiProvider).getHistory(limit: 50);
  debugPrint('Mood History API Response: $result');
  
  final dynamic historyData = result['moods'] ?? result['history'] ?? result['data'];
  if (historyData != null && historyData is List) {
    return historyData;
  }
  return <dynamic>[];
});

// --- Screen --- //

class MoodHistoryScreen extends ConsumerStatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  ConsumerState<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends ConsumerState<MoodHistoryScreen> {
  int _filterDays = 0; // 0 means 'All Time', 7, 14, etc.

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('মেজাজের ইতিহাস', style: TextStyle(fontFamily: 'HindSiliguri')),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterDays = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0, child: Text('সব সময়', style: TextStyle(fontFamily: 'HindSiliguri'))),
              const PopupMenuItem(value: 7, child: Text('গত ৭ দিন', style: TextStyle(fontFamily: 'HindSiliguri'))),
              const PopupMenuItem(value: 14, child: Text('গত ১৪ দিন', style: TextStyle(fontFamily: 'HindSiliguri'))),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
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
    // If filtering is applied, we could theoretically fetch stats for those days,
    // but the API getStats currently only fetches logic without dynamic days easily unless we modify it.
    final statusData = ref.watch(checkinStatusProvider);
    final statsAsyncValue = ref.watch(moodStatsProvider);

    return statsAsyncValue.when(
      data: (statsData) {
        final stats = statsData['stats'];
        if (stats == null || stats['totalEntries'] == 0) {
          return const SizedBox.shrink(); // Hide if no data
        }

        final totalEntries = stats['totalEntries'] as int? ?? 0;
        final distribution = stats['distribution'] as Map<String, dynamic>? ?? {};
        
        // Calculate most frequent mood from distribution
        String? mostFrequentMood;
        int maxCount = 0;
        distribution.forEach((key, value) {
          final count = (value as num).toInt();
          if (count > maxCount) {
            maxCount = count;
            mostFrequentMood = key;
          }
        });

        final currentStreak = statusData.streak; // Use global streak
        
        // Find the emoji for the most frequent mood using backend keys
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
              const Text(
                'গত ৩০ দিনের পরিসংখ্যান',
                style: TextStyle(
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
                    customIcon: Text(freqEmoji, style: const TextStyle(fontSize: 28)),
                    label: 'প্রধান মেজাজ',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStat(
                    icon: Icons.local_fire_department,
                    value: '$currentStreak',
                    label: 'স্ট্রিক 🔥',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStat(
                    icon: Icons.calendar_month,
                    value: '$totalEntries',
                    label: 'মোট এন্ট্রি',
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const _StatsShimmer(),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.cardDecoration(context: context),
        child: const Text('পরিসংখ্যান লোড করতে সমস্যা হয়েছে।', style: TextStyle(color: AppColors.error)),
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
        if (customIcon != null) customIcon
        else if (icon != null) Icon(icon, color: Colors.white, size: 28),
        
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
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontFamily: 'HindSiliguri',
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection(WidgetRef ref, bool isDark, BuildContext context) {
    final historyAsyncValue = ref.watch(moodHistoryProvider);

    return historyAsyncValue.when(
      data: (allHistory) {
        List<dynamic> history = allHistory;
        if (_filterDays > 0) {
          final cutoff = DateTime.now().subtract(Duration(days: _filterDays));
          history = allHistory.where((item) {
            if (item['timestamp'] != null) {
              final date = DateTime.tryParse(item['timestamp'].toString());
              if (date != null) return date.toLocal().isAfter(cutoff);
            }
            return true;
          }).toList();
        }

        if (history.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: Icons.sentiment_neutral_rounded,
                title: 'এখনো কোনো মেজাজ সেভ করা হয়নি',
                description: 'হোম স্ক্রিন থেকে আজ আপনার মেজাজ কেমন তা সেভ করুন',
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final moodData = history[index] as Map<String, dynamic>;
              return _buildMoodItem(context, moodData, isDark);
            },
            childCount: history.length,
          ),
        );
      },
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _TimelineShimmer(),
          childCount: 5,
        ),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'ইতিহাস লোড করতে ব্যর্থ',
            description: error.toString(),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodItem(BuildContext context, Map<String, dynamic> moodData, bool isDark) {
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
      if (index == 0) moodColor = Colors.green; // Happy
      else if (index == 1) moodColor = Colors.lightGreen; // Good
      else if (index == 2) moodColor = Colors.blue; // Neutral
      else if (index == 3) moodColor = Colors.red; // Sad
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
                      mood,
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
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          fontFamily: 'HindSiliguri',
                        ),
                      ),
                  ],
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMMM, yyyy • hh:mm a', 'bn').format(timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary).withOpacity(0.6),
                      fontFamily: 'HindSiliguri',
                    ),
                  ),
                ],
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 16,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
    return ShimmerLoading(
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
