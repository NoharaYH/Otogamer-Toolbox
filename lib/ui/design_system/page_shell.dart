import 'dart:ui';
import 'package:flutter/material.dart';
import 'constants/sizes.dart';
import 'constants/colors.dart';
import 'visual_skins/skin_extension.dart';

/// 页面外壳
/// 提供：背景 + 白色毛玻璃底板 + 内容区域
///
/// 使用场景：主页（需要统一背景和毛玻璃效果的页面）
/// 不使用场景：设置页、WebView 页（这些页面有自己的布局）
class PageShell extends StatelessWidget {
  final Widget child;

  /// Optional override for the background layer.
  /// If provided, this widget will be used instead of the current theme's skin background.
  /// This is useful for HomePage's cross-fading background.
  final Widget? backgroundOverride;

  /// Whether to show the glass-morphism overlay card.
  /// Defaults to true.
  final bool showGlassOverlay;

  const PageShell({
    super.key,
    required this.child,
    this.backgroundOverride,
    this.showGlassOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Get current skin from ThemeExtension
    final skin = Theme.of(context).extension<SkinExtension>();

    // 2. Resolve background: Override > Skin Background > Fallback
    final Widget background =
        backgroundOverride ??
        (skin != null
            ? skin.buildBackground(context)
            : Container(color: UiColors.white)); // Fallback if no skin

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // BOTTOM: The unique background layer
          Positioned.fill(child: background),

          // MIDDLE: The unique glass overlay layer
          if (showGlassOverlay) _buildGlassOverlay(context),

          // TOP: Content layer
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _buildGlassOverlay(BuildContext context) {
    return Positioned(
      top: UiSizes.getTopMarginWithSafeArea(context),
      left: UiSizes.getHorizontalMargin(context),
      right: UiSizes.getHorizontalMargin(context),
      bottom: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          // 悬空包裹向内缩回。由于按钮外边缘距 Glass 有 12pt 的内缩 (Padding)。
          // 以按钮半径 R=16 为圆心计算同心弧：外侧 Glass 半径必须为 16.0 + 12.0 = 28.0。
          // 这样保证从右上角看，按钮圆弧刚好与背景玻璃边缘成绝对完美的等距平行。
          topLeft: Radius.circular(28.0),
          topRight: Radius.circular(28.0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: UiColors.white.withValues(alpha: 0.25),
              border: Border.all(
                color: UiColors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28.0),
                topRight: Radius.circular(28.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
