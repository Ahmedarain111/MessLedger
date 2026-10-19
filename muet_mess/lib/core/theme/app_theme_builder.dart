import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'app_tokens.dart';

/// Single source of truth for building the light and dark [ThemeData].
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final background = isDark ? AppColors.darkBackground : AppColors.lightBackground;
  final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
  final surfaceAlt = isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
  final onSurface = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
  final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
  final border = isDark ? AppColors.borderDark : AppColors.borderLight;
  final primary = isDark ? AppColors.primaryOnDark : AppColors.primary;

  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: primary,
    onPrimary: isDark ? AppColors.primaryDark : Colors.white,
    primaryContainer: isDark ? AppColors.primaryContainerDark : AppColors.primaryContainerLight,
    onPrimaryContainer: isDark ? AppColors.darkOnSurface : AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: isDark ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight,
    onSecondaryContainer: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
    tertiary: AppColors.accent,
    onTertiary: AppColors.primaryDark,
    tertiaryContainer: isDark ? AppColors.tertiaryContainerDark : AppColors.tertiaryContainerLight,
    onTertiaryContainer: isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
    error: isDark ? AppColors.dangerOnDark : AppColors.danger,
    onError: Colors.white,
    errorContainer: isDark ? AppColors.dangerBgDark : AppColors.dangerBg,
    onErrorContainer: isDark ? AppColors.darkOnSurface : AppColors.dangerText,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: muted,
    outline: muted.withValues(alpha: 0.55),
    outlineVariant: border,
    surfaceContainerLowest: surface,
    surfaceContainerLow: surface,
    surfaceContainer: surfaceAlt,
    surfaceContainerHigh: surfaceAlt,
    surfaceContainerHighest: surfaceAlt,
    inverseSurface: isDark ? AppColors.inverseSurfaceDark : AppColors.inverseSurfaceLight,
    onInverseSurface: isDark ? AppColors.darkBackground : Colors.white,
    inversePrimary: isDark ? AppColors.primary : AppColors.primaryOnDark,
    surfaceTint: Colors.transparent,
  );

  final text = _textTheme(scheme);
  final tokens = isDark ? AppTokens.dark : AppTokens.light;

  RoundedRectangleBorder shape(double r) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

  OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    canvasColor: surface,
    textTheme: text,
    extensions: <ThemeExtension<dynamic>>[tokens],
    dividerColor: border,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      titleTextStyle: text.titleLarge?.copyWith(color: onSurface),
      iconTheme: IconThemeData(color: onSurface),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        side: BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      labelStyle: TextStyle(color: muted),
      floatingLabelStyle: TextStyle(color: primary, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: muted.withValues(alpha: 0.8)),
      prefixIconColor: muted,
      suffixIconColor: muted,
      border: inputBorder(border),
      enabledBorder: inputBorder(border),
      focusedBorder: inputBorder(primary, 1.8),
      errorBorder: inputBorder(scheme.error),
      focusedErrorBorder: inputBorder(scheme.error, 1.8),
      disabledBorder: inputBorder(border.withValues(alpha: 0.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: shape(AppSizes.radiusMd),
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        foregroundColor: primary,
        side: BorderSide(color: scheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: shape(AppSizes.radiusMd),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        shape: shape(AppSizes.radiusSm),
        textStyle: text.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(shape: shape(AppSizes.radiusSm)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: shape(AppSizes.radiusMd),
        side: BorderSide(color: border),
        backgroundColor: surface,
        foregroundColor: muted,
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        textStyle: text.labelLarge,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: border),
      backgroundColor: surface,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: primary,
      labelStyle: text.labelLarge?.copyWith(color: onSurface),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: shape(AppSizes.radiusMd),
    ),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface, fontWeight: FontWeight.w600),
      actionTextColor: scheme.inversePrimary,
      shape: shape(AppSizes.radiusMd),
      insetPadding: const EdgeInsets.all(16),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: shape(AppSizes.radiusXl),
      titleTextStyle: text.titleLarge?.copyWith(color: onSurface),
      contentTextStyle: text.bodyMedium?.copyWith(color: muted, height: 1.45),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: surfaceAlt,
      circularTrackColor: surfaceAlt,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 3,
      highlightElevation: 5,
      extendedTextStyle: text.labelLarge,
      shape: shape(AppSizes.radiusLg),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? primary : muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(size: 24, color: selected ? primary : muted);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surface,
      elevation: 0,
      minWidth: 84,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: shape(AppSizes.radiusMd),
      selectedIconTheme: IconThemeData(color: primary, size: 24),
      unselectedIconTheme: IconThemeData(color: muted, size: 24),
      selectedLabelTextStyle: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w500),
    ),
  );
}

TextTheme _textTheme(ColorScheme s) {
  return TextTheme(
    displaySmall: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.1),
    headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.15),
    headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15),
    headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.2),
    titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.25),
    titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.1, height: 1.3),
    titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3),
    bodyLarge: const TextStyle(fontSize: 16, height: 1.45),
    bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
    bodySmall: TextStyle(fontSize: 12.5, height: 1.35, color: s.onSurfaceVariant),
    labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.1),
    labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
  );
}
