import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Semantic design tokens that do not exist in Material's [ColorScheme]:
/// status colors, shift colors and hero gradients. Read them with
/// `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.pending,
    required this.disputed,
    required this.overdue,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.heroGradient,
    required this.owingGradient,
    required this.onHero,
    required this.softShadow,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color pending;
  final Color disputed;
  final Color overdue;

  final Color breakfast;
  final Color lunch;
  final Color dinner;

  final List<Color> heroGradient;
  final List<Color> owingGradient;
  final Color onHero;
  final Color softShadow;

  static const light = AppTokens(
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
    pending: AppColors.pending,
    disputed: AppColors.disputed,
    overdue: AppColors.overdue,
    breakfast: AppColors.shiftBreakfast,
    lunch: AppColors.shiftLunch,
    dinner: AppColors.shiftDinner,
    heroGradient: [AppColors.heroStartLight, AppColors.heroEndLight],
    owingGradient: [AppColors.owingStart, AppColors.owingEnd],
    onHero: Colors.white,
    softShadow: Color(0x141B1B2F),
  );

  static const dark = AppTokens(
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.dangerOnDark,
    info: AppColors.info,
    pending: AppColors.pending,
    disputed: AppColors.disputed,
    overdue: AppColors.overdue,
    breakfast: AppColors.shiftBreakfast,
    lunch: AppColors.shiftLunch,
    dinner: AppColors.shiftDinner,
    heroGradient: [AppColors.heroStartDark, AppColors.heroEndDark],
    owingGradient: [AppColors.owingStart, AppColors.owingEnd],
    onHero: Colors.white,
    softShadow: Color(0x66000000),
  );

  @override
  AppTokens copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? pending,
    Color? disputed,
    Color? overdue,
    Color? breakfast,
    Color? lunch,
    Color? dinner,
    List<Color>? heroGradient,
    List<Color>? owingGradient,
    Color? onHero,
    Color? softShadow,
  }) {
    return AppTokens(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      pending: pending ?? this.pending,
      disputed: disputed ?? this.disputed,
      overdue: overdue ?? this.overdue,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      heroGradient: heroGradient ?? this.heroGradient,
      owingGradient: owingGradient ?? this.owingGradient,
      onHero: onHero ?? this.onHero,
      softShadow: softShadow ?? this.softShadow,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> lg(List<Color> a, List<Color> b) =>
        [for (var i = 0; i < a.length && i < b.length; i++) l(a[i], b[i])];
    return AppTokens(
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
      info: l(info, other.info),
      pending: l(pending, other.pending),
      disputed: l(disputed, other.disputed),
      overdue: l(overdue, other.overdue),
      breakfast: l(breakfast, other.breakfast),
      lunch: l(lunch, other.lunch),
      dinner: l(dinner, other.dinner),
      heroGradient: lg(heroGradient, other.heroGradient),
      owingGradient: lg(owingGradient, other.owingGradient),
      onHero: l(onHero, other.onHero),
      softShadow: l(softShadow, other.softShadow),
    );
  }
}

extension AppTokensContext on BuildContext {
  /// Design tokens for the current theme (falls back to the matching
  /// built-in set if the extension is not installed, e.g. in tests).
  AppTokens get tokens {
    final theme = Theme.of(this);
    return theme.extension<AppTokens>() ??
        (theme.brightness == Brightness.dark ? AppTokens.dark : AppTokens.light);
  }
}
