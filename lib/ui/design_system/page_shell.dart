import 'dart:ui';
import 'package:flutter/material.dart';
import '../../shared/models/glass_overlay_prefs.dart';
import 'constants/sizes.dart';
import 'constants/colors.dart';
import 'theme/core/app_theme.dart';

/// 页面外壳
/// 提供：背景 + 白色毛玻璃底板 + 内容区域
///
/// 【架构红线】不判断设备形态、不包含侧边栏/热区/平板状态；showGlassOverlay 由调用方（如 RootPage）
/// 根据 compact/expanded 传入，本组件内部无 MediaQuery 或 ResponsiveLayoutScope 分支。
///
/// 使用场景：主页（需要统一背景和毛玻璃效果的页面）
/// 不使用场景：设置页、WebView 页（这些页面有自己的布局）
class PageShell extends StatelessWidget {
  final Widget child;

  /// Optional override for the background layer.
  /// If provided, this widget will be used instead of the current theme's skin background.
  /// This is useful for HomePage's cross-fading background.
  final Widget? backgroundOverride;

  /// Whether to show the glass-morphism overlay card. 【平板 vs 手机】由调用方根据 compact 传入，Compact 为 true，Medium+ 为 false（平板玻璃在 Shell 内）。
  /// Defaults to true.
  final bool showGlassOverlay;

  /// 玻璃层可选配置。由 RootPage 从 GameProvider.glassOverlayPrefs 传入；null 时使用默认（全开、当前视觉效果）。
  final GlassOverlayPrefs? glassOverlayConfig;

  const PageShell({
    super.key,
    required this.child,
    this.backgroundOverride,
    this.showGlassOverlay = true,
    this.glassOverlayConfig,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Get current skin from ThemeExtension
    final skin = Theme.of(context).extension<AppTheme>();

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
          if (showGlassOverlay) _buildGlassOverlay(context, glassOverlayConfig),

          // TOP: Content layer
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _buildGlassOverlay(BuildContext context, GlassOverlayPrefs? config) {
    const borderRadius = BorderRadius.only(
      topLeft: Radius.circular(28.0),
      topRight: Radius.circular(28.0),
    );

    final prefs = config?.normalized();

    final glassStack = Stack(
      fit: StackFit.expand,
      children: [
        _buildGlassFillLayer(prefs),
        if (prefs == null || prefs.strokeEnabled)
          CustomPaint(painter: _GlassStrokePainter()),
      ],
    );

    return Positioned(
      top: UiSizes.getTopMarginWithSafeArea(context),
      left: UiSizes.getHorizontalMargin(context),
      right: UiSizes.getHorizontalMargin(context),
      bottom: 0,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: glassStack,
      ),
    );
  }

  static const double _blurSigma = 12.0;
  static const double _opacityTop = 0.50;
  static const double _opacityBottom = 0.24;

  Widget _buildGlassFillLayer(GlassOverlayPrefs? prefs) {
    if (prefs == null) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                UiColors.white.withValues(alpha: _opacityTop),
                UiColors.white.withValues(alpha: _opacityBottom),
              ],
            ),
          ),
        ),
      );
    }

    if (!prefs.opacityEnabled) {
      return Container(color: UiColors.white);
    }

    final fillChild = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            UiColors.white.withValues(alpha: _opacityTop),
            UiColors.white.withValues(alpha: _opacityBottom),
          ],
        ),
      ),
    );

    if (prefs.blurEnabled) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: fillChild,
      );
    }
    return fillChild;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 描边 Painter：渐变描边（左上白 → 右下透明，硬编码）
// ─────────────────────────────────────────────────────────────────────────────

class _GlassStrokePainter extends CustomPainter {
  _GlassStrokePainter();

  static const double _topRadius = 28.0;
  static const double _strokeWidth = 2.25;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(_topRadius),
      topRight: const Radius.circular(_topRadius),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Colors.transparent],
        stops: const [0.0, 0.7],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
