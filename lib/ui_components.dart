import 'package:flutter/material.dart';

class TechColors {
  static const Color primary = Color(0xFF00D2FF);
  static const Color secondary = Color(0xFF3A7BD5);
  static const Color accent = Colors.orangeAccent;
  static const Color backgroundDark = Color(0xFF0F2027);
  static const Color backgroundDarkEnd = Color(0xFF2C5364);
  static const Color cardDark = Color(0x22FFFFFF);
}

class TechButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final int flex;
  final bool isOperator;
  final double verticalPadding;

  const TechButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.flex = 1,
    this.isOperator = false,
    this.verticalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: color != null
                      ? [color!, color!.withAlpha(204)]
                      : (isDarkMode
                      ? [Colors.white.withAlpha(25), Colors.white.withAlpha(13)]
                      : [Colors.black.withAlpha(13), Colors.black.withAlpha(3)]),
                ),
                border: Border.all(
                  color: isOperator
                      ? TechColors.accent.withAlpha(128)
                      : (isDarkMode ? Colors.white10 : Colors.black12),
                  width: 1,
                ),
                boxShadow: [
                  if (isOperator)
                    BoxShadow(
                      color: TechColors.accent.withAlpha(51),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: text.length > 2 ? 18 : 24,
                    fontWeight: isOperator ? FontWeight.bold : FontWeight.normal,
                    color: textColor ?? (isOperator
                        ? (isDarkMode ? TechColors.accent : Colors.deepOrange)
                        : (isDarkMode ? Colors.white : Colors.black87)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 10,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha((opacity * 255).round()),
            Colors.white.withAlpha((opacity * 127).round()),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
