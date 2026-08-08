import 'package:flutter/material.dart';

abstract final class SkinFlowColors {
  static const appBackground = Color(0xFF151218);
  static const card = Color(0xFF211E24);
  static const cardEmphasized = Color(0xFF2C292F);
  static const primaryText = Color(0xFFE7E0E8);
  static const secondaryText = Color(0xFFCBC4CF);
  static const subtleBorder = Color(0xFF4A454E);
  static const primary = Color(0xFFD6BBFB);
  static const primaryContainer = Color(0xFF523C73);
  static const onPrimaryContainer = Color(0xFFEDDCFF);
  static const selectedContainer = Color(0xFF574D61);
  static const morning = Color(0xFFF2B7C2);
  static const retinal = Color(0xFFD6BBFB);
  static const exfoliation = Color(0xFFF4BE8A);
  static const recovery = Color(0xFFA7D7C5);
  static const safety = Color(0xFFF2B8B5);
  static const missed = Color(0xFF625D66);
}

ThemeData buildSkinFlowTheme() {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: SkinFlowColors.primary,
    brightness: Brightness.dark,
  );
  final scheme = baseScheme.copyWith(
    primary: SkinFlowColors.primary,
    primaryContainer: SkinFlowColors.primaryContainer,
    onPrimaryContainer: SkinFlowColors.onPrimaryContainer,
    surface: SkinFlowColors.appBackground,
    surfaceContainer: SkinFlowColors.card,
    surfaceContainerHigh: SkinFlowColors.cardEmphasized,
    onSurface: SkinFlowColors.primaryText,
    onSurfaceVariant: SkinFlowColors.secondaryText,
    outline: const Color(0xFF938E97),
    outlineVariant: SkinFlowColors.subtleBorder,
    error: SkinFlowColors.safety,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: SkinFlowColors.appBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: SkinFlowColors.appBackground,
      foregroundColor: SkinFlowColors.primaryText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: SkinFlowColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: SkinFlowColors.card,
      indicatorColor: SkinFlowColors.selectedContainer,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, color: SkinFlowColors.primaryText),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? SkinFlowColors.primaryText
              : SkinFlowColors.secondaryText,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(0, 36)),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SkinFlowColors.selectedContainer
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.all(SkinFlowColors.primaryText),
        side: WidgetStateProperty.all(
          const BorderSide(color: Color(0xFF938E97)),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? SkinFlowColors.primaryContainer
            : SkinFlowColors.secondaryText,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? SkinFlowColors.primary
            : SkinFlowColors.cardEmphasized,
      ),
      trackOutlineColor: WidgetStateProperty.all(const Color(0xFF938E97)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SkinFlowColors.primary,
        foregroundColor: const Color(0xFF3A2652),
        minimumSize: const Size(0, 48),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: SkinFlowColors.primary,
      linearTrackColor: SkinFlowColors.selectedContainer,
    ),
    dividerTheme: const DividerThemeData(
      color: SkinFlowColors.subtleBorder,
      thickness: 1,
      space: 1,
    ),
  );
}
