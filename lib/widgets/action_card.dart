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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive sizes based on available space
              final availableHeight = constraints.maxHeight;
              final iconSize = availableHeight > 120 ? 24.0 : 20.0;
              final iconPadding = availableHeight > 120 ? 10.0 : 8.0;
              final mainSpacing = availableHeight > 120 ? 10.0 : 6.0;
              final labelSize = availableHeight > 120 ? 14.0 : 12.0;
              final subtitleSize = availableHeight > 120 ? 11.0 : 10.0;

              return Column(
                crossAxisAlignment: contentAlignment,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconContentColor, size: iconSize),
                  ),
                  SizedBox(height: mainSpacing),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Column(
                      crossAxisAlignment: contentAlignment,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            textAlign: textAlignment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: labelSize,
                              color: cardTextColor,
                              height: 1.1,
                            ),
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          SizedBox(height: mainSpacing / 3),
                          Flexible(
                            child: Text(
                              subtitle,
                              textAlign: textAlignment,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: subtitleSize,
                                color: subtitleColor,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
