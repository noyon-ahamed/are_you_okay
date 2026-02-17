import 'package:flutter/material.dart';

/// Status badge widget showing safety status indicators
class StatusBadge extends StatelessWidget {
  final StatusType type;
  final String label;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({
    super.key,
    required this.type,
    required this.label,
    this.fontSize = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _getColor(),
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
              fontFamily: 'HindSiliguri',
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (type) {
      case StatusType.safe:
        return const Color(0xFF4CAF50);
      case StatusType.warning:
        return const Color(0xFFFF9800);
      case StatusType.danger:
        return const Color(0xFFF44336);
      case StatusType.offline:
        return const Color(0xFF757575);
      case StatusType.info:
        return const Color(0xFF2196F3);
      case StatusType.premium:
        return const Color(0xFFFFA500);
    }
  }
}

enum StatusType {
  safe,
  warning,
  danger,
  offline,
  info,
  premium,
}
