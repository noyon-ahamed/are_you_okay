import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer loading placeholder
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFF5F5F5),
      child: Container(
        margin: margin,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Card-shaped shimmer placeholder
  factory ShimmerLoading.card({
    double height = 120,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerLoading(
      height: height,
      borderRadius: 16,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// Circle shimmer (for avatars)
  factory ShimmerLoading.circle({double size = 48}) {
    return ShimmerLoading(
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  /// Line shimmer (for text placeholders)
  factory ShimmerLoading.line({
    double width = double.infinity,
    double height = 16,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerLoading(
      width: width,
      height: height,
      borderRadius: 4,
      margin: margin,
    );
  }
}

/// A shimmer list placeholder showing multiple loading cards
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(
          itemCount,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ShimmerLoading.circle(size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading.line(width: 150, height: 14),
                      const SizedBox(height: 8),
                      ShimmerLoading.line(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
