import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final Color color;
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final CrossAxisAlignment contentAlignment;
  final TextAlign textAlignment;

  const ActionCard({
    super.key,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.elevation,
    this.padding,
    this.borderRadius,
    this.contentAlignment = CrossAxisAlignment.center,
    this.textAlignment = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Original Look: Dark cards on the colored background
    final cardBgColor = isDark
        ? const Color(0xFF2D2722)
        : const Color(0xFF1A1613);
    final mainTextColor = Colors.white;
    final subTextColor = Colors.white70;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: borderRadius ?? BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              borderRadius as BorderRadius? ?? BorderRadius.circular(28),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: contentAlignment,
              children: [
                // Icon in a rounded square
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color, // The "Gold/Brown" accent color
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? Colors.black87,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  textAlign: textAlignment,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: mainTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: textAlignment,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subTextColor,
                    fontSize: 10,
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
