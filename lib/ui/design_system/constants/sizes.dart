import 'package:flutter/material.dart';

class UiSizes {
  // --- Global Layout Multipliers (Architecture Constants) ---
  /// The starting vertical offset for the main glass card (5% of screen height)
  static const double shellMarginTopMultiplier = 0.05;

  /// The horizontal margin for the main glass card (3% of screen width)
  static const double shellMarginSideMultiplier = 0.03;

  // --- Spacing System (The Unified Standard) ---
  /// 4.0 - Extra small spacing
  static const double spaceXXS = 4.0;

  /// 8.0 - Small spacing
  static const double spaceXS = 8.0;

  /// 12.0 - The Eternal Margin (Atomic Standard)
  static const double spaceS = 12.0;

  /// 16.0 - The Global Standard Padding
  static const double spaceM = 16.0;

  /// 24.0 - Large spacing (Gaps between logical sections)
  static const double spaceL = 24.0;

  /// 32.0 - Header area gaps
  static const double spaceXL = 32.0;

  // --- Functional Aliases ---
  /// 12.0 - 核心组件之间的标准间距 (红框中的垂直间距)
  static const double atomicComponentGap = spaceS;

  /// 12.0 - 卡片内容的侧边对齐标准 (红框中的左右缩进)
  static const double cardContentPadding = spaceS;

  static const double defaultPadding = spaceM;
  static const double cardInnerPadding = spaceM;
  static const double sectionGap = spaceL;

  // --- Component Specifics ---
  static const double cardBorderRadius = 20.0;
  static const double buttonBorderRadius = 12.0;
  static const double inputFieldHeight = 44.0;
  static const double logoHeight = 80.0;
  static const double logoAreaHeight = 100.0;

  /// 基础表单/头部/Tabs 的预估高度占用
  static const double syncFormEstimatedHeight = 464.0;

  // --- Animation ---
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);

  // --- Helper Methods for Consistent Layout ---
  /// Returns a fixed 12px margin to ensure the glass shell has breathing room from screen edges.
  static double getHorizontalMargin(BuildContext context) {
    return spaceS;
  }

  /// Returns the top margin in absolute pixels
  static double getTopMargin(BuildContext context) {
    return MediaQuery.of(context).size.height * shellMarginTopMultiplier;
  }

  /// Returns top margin that respects device safe area (notch, status bar).
  /// If the safe area top inset is larger than the standard top margin,
  /// we add a small extra offset (8.0) to avoid the overlay touching the notch.
  static double getTopMarginWithSafeArea(BuildContext context) {
    final double base = getTopMargin(context);
    final double safeTop = MediaQuery.of(context).viewPadding.top;
    if (safeTop > base) {
      return safeTop + 8.0; // extra spacing after notch
    }
    return base;
  }

  /// Returns the standard padding for page content (Logo + Card stack)
  static EdgeInsets getPageContentPadding(BuildContext context) {
    return EdgeInsets.only(
      top: getTopMargin(context),
      left: getHorizontalMargin(context),
      right: getHorizontalMargin(context),
    );
  }

  /// Returns the horizontal margin for the card, including inner padding
  static double getCardSideMargin(BuildContext context) {
    return getHorizontalMargin(context) + cardContentPadding;
  }

  /// Returns the bottom margin for the card, respecting 3% screen rule + spaceS
  static double getCardBottomMargin(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight * 0.03) + spaceS;
  }

  /// Returns the pure bottom safe area margin
  static double getBottomMarginWithSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Calculates the available height for the log panel to ensure the card
  /// touches the bottom at the 3% adaptive margin standard.
  static double getLogPanelMaxHeight(
    BuildContext context,
    double currentUsedHeight,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topMargin = getTopMarginWithSafeArea(context);
    final bottomMargin = getCardBottomMargin(context);

    // ReservedSpace = TotalHeight - TopMargin - UsedHeight - BottomMargin
    final available =
        screenHeight - topMargin - currentUsedHeight - bottomMargin;

    return available > 100 ? available : 180;
  }

  /// Returns the top offset for the dot indicator
  static double getDotIndicatorTop(BuildContext context) {
    return getTopMargin(context) + logoAreaHeight - spaceS;
  }
}
