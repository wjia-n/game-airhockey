import 'package:flutter/material.dart';
import 'rink_themes.dart';

/// Arcade Rink — the design system for Air Hockey.
/// Warm physical materials: real woods, ivory laminate, painted lines,
/// jewel-tone strikers. No neon, no cyberpunk, no generic Material look.
///
/// All widgets accept an optional [RinkThemeDef]; they default to the
/// Classic Arcade theme so call sites keep working.
class Rink {
  static const displayFont = 'serif';

  static TextStyle display(double size, {Color? color, RinkThemeDef? theme}) =>
      TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Color(0xFF1A0F08), offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, RinkThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.ivory ?? const Color(0xFFF5EFE0),
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, RinkThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 0.8,
      );

  static ThemeData theme([RinkThemeDef? t]) {
    t ??= RinkThemes.byId('classic');
    final darkText = t.id == 'maple' || t.id == 'sandstone' || t.id == 'forest';
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.woodDeep,
      colorScheme: ColorScheme(
        brightness: darkText ? Brightness.light : Brightness.dark,
        primary: t.accent,
        onPrimary: t.woodDeep,
        secondary: t.accentLight,
        onSecondary: t.woodDeep,
        surface: t.railMid,
        onSurface: t.ivory,
        error: t.sideColors[0],
        onError: t.ivory,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(15, theme: t),
      ),
    );
  }
}

/// Warm wooden backdrop with a soft vignette, themed per table.
class RinkBackdrop extends StatelessWidget {
  final RinkThemeDef theme;
  final Widget child;
  const RinkBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.4,
          colors: [theme.railMid, theme.woodDeep],
        ),
      ),
      child: child,
    );
  }
}

/// Big wooden primary button.
class RinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final RinkThemeDef theme;
  final double width;
  final bool primary;

  const RinkButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.theme,
    this.width = 260,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: primary
              ? LinearGradient(colors: [t.accentLight, t.accent, t.accentDark])
              : LinearGradient(colors: [t.railMid, t.railDark]),
          border: Border.all(
              color: primary ? t.accentLight : t.railLight, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(0, 5),
              blurRadius: 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Rink.label(18,
              theme: t, color: primary ? t.woodDeep : t.ivory),
        ),
      ),
    );
  }
}

/// Wooden card section used on menu/settings/pro screens.
class RinkCard extends StatelessWidget {
  final String title;
  final RinkThemeDef theme;
  final List<Widget> children;

  const RinkCard({
    super.key,
    required this.title,
    required this.theme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [t.railMid, t.railDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: t.accent.withValues(alpha: 0.55), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Rink.label(16, theme: t)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// Small circular menu icon button (Share / Rate / Settings / Help).
class RinkIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final RinkThemeDef theme;
  final VoidCallback onTap;

  const RinkIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [t.railLight, t.railDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              border: Border.all(color: t.accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: t.accentLight, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: Rink.label(11, theme: t)),
        ],
      ),
    );
  }
}

/// Segmented option row (e.g. difficulty or mode picker).
class RinkSegmented<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onSelect;
  final RinkThemeDef theme;
  final List<bool> locked;

  const RinkSegmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onSelect,
    required this.theme,
    this.locked = const [],
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Row(
      children: [
        for (int i = 0; i < values.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(values[i]),
              child: Container(
                margin: EdgeInsets.only(
                    right: i == values.length - 1 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: values[i] == selected
                      ? LinearGradient(
                          colors: [t.accentLight, t.accent])
                      : null,
                  color: values[i] == selected
                      ? null
                      : Colors.black.withValues(alpha: 0.3),
                  border: Border.all(
                    color: values[i] == selected
                        ? t.accentLight
                        : t.accent.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (locked.length > i && locked[i])
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.lock,
                            size: 13,
                            color: values[i] == selected
                                ? t.woodDeep
                                : t.ivory.withValues(alpha: 0.6)),
                      ),
                    Text(
                      labels[i],
                      style: Rink.label(13,
                          theme: t,
                          color: values[i] == selected
                              ? t.woodDeep
                              : t.ivory),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
