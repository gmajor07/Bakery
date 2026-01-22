// lib/widgets/action_card.dart
import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final Color color;
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool? useDefaultColors;
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
    this.useDefaultColors = true,
    this.elevation = 2,
    this.padding,
    this.borderRadius,
    this.contentAlignment = CrossAxisAlignment.start,
    this.textAlignment = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determine colors based on useDefaultColors flag
    final surfaceColor = useDefaultColors!
        ? colorScheme.background
        : colorScheme.onSurface.withOpacity(0.05);
    final cardTextColor =
        textColor ??
        (useDefaultColors!
            ? textTheme.bodyMedium?.color
            : colorScheme.onSurface);
    final subtitleColor = cardTextColor?.withOpacity(0.6);
    final iconBgColor = useDefaultColors! ? color.withOpacity(0.9) : color;
    final iconContentColor =
        iconColor ??
        (useDefaultColors! ? colorScheme.onPrimary : colorScheme.onSurface);

    return Material(
      color: surfaceColor,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      elevation: elevation ?? 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: contentAlignment,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconContentColor, size: 24),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: contentAlignment,
                children: [
                  Text(
                    label,
                    textAlign: textAlignment,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: cardTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textAlign: textAlignment,
                    style: TextStyle(fontSize: 11, color: subtitleColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
