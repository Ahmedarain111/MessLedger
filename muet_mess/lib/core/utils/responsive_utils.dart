import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

enum ScreenSize { mobile, tablet, desktop }

/// Responsive helpers around MediaQuery/LayoutBuilder.
class ResponsiveUtils {
  ResponsiveUtils._();

  static ScreenSize of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= AppSizes.mobileMax) return ScreenSize.mobile;
    if (w <= AppSizes.tabletMax) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static bool isMobile(BuildContext context) => of(context) == ScreenSize.mobile;

  static int crossAxisCount(BuildContext context, {int desktop = 4, int tablet = 2, int mobile = 1}) {
    switch (of(context)) {
      case ScreenSize.desktop:
        return desktop;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.mobile:
        return mobile;
    }
  }
}
