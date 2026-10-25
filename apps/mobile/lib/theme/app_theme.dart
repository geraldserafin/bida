import 'package:flutter/material.dart';

/// shadcn-inspired themes (dark + light): flat surfaces, hairline borders,
/// near-mono primary actions, Inter type, generous rounding.
class AppTheme {
  static ThemeData get theme => dark;
  static ThemeData get dark => _build(_DarkPalette());
  static ThemeData get light => _build(_LightPalette());

  static ThemeData _build(_Palette p) {
    final scheme =
        (p.brightness == Brightness.dark
                ? const ColorScheme.dark()
                : const ColorScheme.light())
            .copyWith(
              brightness: p.brightness,
              primary: p.primary,
              onPrimary: p.onPrimary,
              primaryContainer: p.track,
              onPrimaryContainer: p.fg,
              secondary: p.muted,
              onSecondary: p.onPrimary,
              surface: p.bg,
              onSurface: p.fg,
              onSurfaceVariant: p.muted,
              surfaceContainerLowest: p.bg,
              surfaceContainerLow: p.card,
              surfaceContainer: p.card,
              surfaceContainerHigh: p.border,
              surfaceContainerHighest: p.track,
              outline: p.outline,
              outlineVariant: p.track,
              error: p.error,
              onError: p.onPrimary,
              errorContainer: p.errorContainer,
              onErrorContainer: p.onErrorContainer,
            );

    final base = ThemeData(
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      useMaterial3: true,
      fontFamily: 'Inter',
    );

    final text = base.textTheme
        .apply(bodyColor: p.fg, displayColor: p.fg)
        .copyWith(
          titleLarge: base.textTheme.titleLarge?.copyWith(
            letterSpacing: -0.3,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            letterSpacing: -0.2,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            letterSpacing: -0.4,
            fontWeight: FontWeight.w700,
          ),
        );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.track, thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.bg,
        indicatorColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? p.fg : p.faint,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? p.fg : p.faint,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.fg,
          side: BorderSide(color: p.track),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: p.muted),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.track),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.track),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.fg, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.card,
        contentTextStyle: TextStyle(color: p.fg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Palette knobs shared by both themes.
abstract class _Palette {
  Brightness get brightness;
  Color get bg;
  Color get card;
  Color get border;
  Color get track;
  Color get fg;
  Color get muted;
  Color get faint;
  Color get primary;
  Color get onPrimary;
  Color get outline;
  Color get error;
  Color get errorContainer;
  Color get onErrorContainer;
}

class _DarkPalette implements _Palette {
  @override
  final brightness = Brightness.dark;
  @override
  final bg = const Color(0xFF09090B);
  @override
  final card = const Color(0xFF131316);
  @override
  final border = const Color(0xFF1F1F23);
  @override
  final track = const Color(0xFF27272A);
  @override
  final fg = const Color(0xFFFAFAFA);
  @override
  final muted = const Color(0xFFA1A1AA);
  @override
  final faint = const Color(0xFF71717A);
  @override
  final primary = const Color(0xFFFAFAFA);
  @override
  final onPrimary = const Color(0xFF09090B);
  @override
  final outline = const Color(0xFF3F3F46);
  @override
  final error = const Color(0xFFF87171);
  @override
  final errorContainer = const Color(0xFF4C0519);
  @override
  final onErrorContainer = const Color(0xFFFECDD3);
}

class _LightPalette implements _Palette {
  @override
  final brightness = Brightness.light;
  @override
  final bg = const Color(0xFFF4F4F5);
  @override
  final card = const Color(0xFFFFFFFF);
  @override
  final border = const Color(0xFFE4E4E7);
  @override
  final track = const Color(0xFFE4E4E7);
  @override
  final fg = const Color(0xFF09090B);
  @override
  final muted = const Color(0xFF52525B);
  @override
  final faint = const Color(0xFF71717A);
  @override
  final primary = const Color(0xFF18181B);
  @override
  final onPrimary = const Color(0xFFFAFAFA);
  @override
  final outline = const Color(0xFFD4D4D8);
  @override
  final error = const Color(0xFFDC2626);
  @override
  final errorContainer = const Color(0xFFFEE2E2);
  @override
  final onErrorContainer = const Color(0xFF7F1D1D);
}
