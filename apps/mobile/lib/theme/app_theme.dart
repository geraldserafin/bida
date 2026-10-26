import 'package:flutter/material.dart';

/// Themes built from the tokens of the BIDA design (Figma "BIDA – ekrany
/// aplikacji"): flat surfaces, hairline borders, a near-white pill as the main
/// action, green for money coming in and amber for estimates. The design is
/// dark; the light theme mirrors it.
class AppTheme {
  static ThemeData get theme => dark;
  static ThemeData get dark => _build(AppColors.dark);
  static ThemeData get light => _build(AppColors.light);

  static ThemeData _build(AppColors c) {
    final scheme =
        (c.brightness == Brightness.dark
                ? const ColorScheme.dark()
                : const ColorScheme.light())
            .copyWith(
              brightness: c.brightness,
              primary: c.primary,
              onPrimary: c.onPrimary,
              primaryContainer: c.surface2,
              onPrimaryContainer: c.text,
              secondary: c.textMuted,
              onSecondary: c.onPrimary,
              tertiary: c.accent,
              surface: c.background,
              onSurface: c.text,
              onSurfaceVariant: c.textMuted,
              surfaceContainerLowest: c.background,
              surfaceContainerLow: c.surface,
              surfaceContainer: c.surface,
              surfaceContainerHigh: c.border,
              surfaceContainerHighest: c.surface2,
              outline: c.borderStrong,
              outlineVariant: c.border,
              error: c.danger,
              onError: c.onPrimary,
              errorContainer: c.dangerContainer,
              onErrorContainer: c.danger,
            );

    final base = ThemeData(
      brightness: c.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      useMaterial3: true,
      fontFamily: 'Inter',
    );

    final text = base.textTheme
        .copyWith(
          // Kwota/XL
          displaySmall: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
          // Nagłówek/H1
          headlineMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          // Nagłówek/H2
          headlineSmall: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
          // Nagłówek/H3
          titleMedium: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          // Tekst/Mocny
          titleSmall: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          // Tekst/Zwykły
          bodyLarge: const TextStyle(fontSize: 15, height: 1.5),
          // Tekst/Mały
          bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
          // Podpis
          bodySmall: const TextStyle(fontSize: 12, height: 1.45),
          // Etykieta
          labelLarge: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          // Nadtytuł
          labelSmall: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.72,
          ),
        )
        .apply(bodyColor: c.text, displayColor: c.text, fontFamily: 'Inter');
    // captions and overlines are muted
    final textTheme = text.copyWith(
      bodySmall: text.bodySmall?.copyWith(color: c.textMuted),
      labelSmall: text.labelSmall?.copyWith(color: c.textMuted),
    );

    const pill = StadiumBorder();
    const buttonText = TextStyle(
      fontFamily: 'Inter',
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return base.copyWith(
      textTheme: textTheme,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          disabledBackgroundColor: c.surface2,
          disabledForegroundColor: c.textMuted,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          side: BorderSide(color: c.borderStrong),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.textMuted,
          textStyle: buttonText.copyWith(fontSize: 15),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
        dragHandleSize: const Size(40, 4),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: c.borderStrong),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: c.textMuted),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.surface2,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : null,
        ),
        checkColor: WidgetStateProperty.all(c.onPrimary),
        side: BorderSide(color: c.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: c.textMuted, fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.borderStrong),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.accent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.danger),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface2,
        contentTextStyle: TextStyle(color: c.text, fontFamily: 'Inter'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// The design's colour tokens, reachable with `AppColors.of(context)` for
/// what [ColorScheme] has no slot for (estimates, the accent, soft text).
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textSoft,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.estimate,
    required this.estimateBorder,
    required this.warning,
    required this.danger,
    required this.dangerContainer,
  });

  final Brightness brightness;

  /// tło
  final Color background;

  /// powierzchnia
  final Color surface;

  /// powierzchnia-2
  final Color surface2;

  /// obramowanie
  final Color border;

  /// obramowanie-mocne
  final Color borderStrong;

  /// tekst
  final Color text;

  /// tekst-miękki
  final Color textSoft;

  /// tekst-wyciszony
  final Color textMuted;

  /// główny
  final Color primary;

  /// na-głównym
  final Color onPrimary;

  /// akcent: money coming in, the balance, what is chosen
  final Color accent;

  /// szacunkowe: amounts that are only estimated
  final Color estimate;

  /// szacunkowe-obramowanie
  final Color estimateBorder;

  /// ostrzeżenie
  final Color warning;

  /// niebezpieczne
  final Color danger;
  final Color dangerContainer;

  static const dark = AppColors(
    brightness: Brightness.dark,
    background: Color(0xFF0B0B0C),
    surface: Color(0xFF17171A),
    surface2: Color(0xFF27272A),
    border: Color(0xFF26262B),
    borderStrong: Color(0xFF3F3F46),
    text: Color(0xFFF4F4F5),
    textSoft: Color(0xFFD4D4D8),
    textMuted: Color(0xFFA1A1AA),
    primary: Color(0xFFFAFAFA),
    onPrimary: Color(0xFF0B0B0C),
    accent: Color(0xFF34D399),
    estimate: Color(0xFFF5B544),
    estimateBorder: Color(0xFF8A6A2A),
    warning: Color(0xFFFB923C),
    danger: Color(0xFFFCA5A5),
    dangerContainer: Color(0xFF3B1414),
  );

  static const light = AppColors(
    brightness: Brightness.light,
    background: Color(0xFFF4F4F5),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE4E4E7),
    border: Color(0xFFE4E4E7),
    borderStrong: Color(0xFFD4D4D8),
    text: Color(0xFF09090B),
    textSoft: Color(0xFF3F3F46),
    textMuted: Color(0xFF52525B),
    primary: Color(0xFF18181B),
    onPrimary: Color(0xFFFAFAFA),
    accent: Color(0xFF059669),
    estimate: Color(0xFFB45309),
    estimateBorder: Color(0xFFD9A54A),
    warning: Color(0xFFEA580C),
    danger: Color(0xFFDC2626),
    dangerContainer: Color(0xFFFEE2E2),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? dark;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}
