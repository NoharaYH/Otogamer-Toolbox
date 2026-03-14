import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/shared/navigation_provider.dart';
import '../../shared/models/glass_overlay_prefs.dart';
import 'constants/animations.dart';
import 'constants/colors.dart';
import 'constants/layout_analyzer.dart';
import 'constants/responsive_layout_scope.dart';
import 'constants/sizes.dart';
import 'kit_navigation/nav_deck_overlay.dart';
import 'kit_navigation/tablet_sidebar_controller.dart';
import 'kit_navigation/tablet_sidebar_minimal.dart';
import 'kit_shared/kit_action_circle.dart';
import 'kit_shared/kit_animation_engine.dart';
import 'theme/core/app_theme.dart';

const double _defaultPrimaryRatio = 0.5;
const double _minPaneWidth = 280.0;

// Tablet-only constants (not in global UiSizes).
const double _tabletNavCapsuleMaxWidthWithText = 166.0;
const double _tabletStandardSize = 24.0;
double get _tabletGlassMargin =>
    (_tabletNavCapsuleMaxWidthWithText + 5 * _tabletStandardSize) / 2.0;

/// 应用级响应式壳层。物理位置为 PageShell 的 child。
///
/// 职责：
/// - 读取 MediaQuery 调用纯函数布局分析器（断点唯一定义在 layout_analyzer）
/// - 将分析结果翻译为布局意图并通过 ResponsiveLayoutScope 下发
/// - 【架构红线·唯一分支点】isCompact ? _buildCompactLayout : _buildExpandedLayout，两条子树严格分离
/// - Compact（手机）：渲染 NavDeckOverlay + 左侧手势热区 + _buildActionButtons(showMenu: true)
/// - Medium+（平板）：渲染平板玻璃层 + 两侧热区 + TabletSidebarMinimal，状态仅 TabletSidebarController
///
/// 不负责：持有业务状态、决定业务模块是否存在、将断点信息上传至 application/
class OtokitResponsiveShell extends StatefulWidget {
  /// 页面内容（AnimatedSwitcher 包裹的当前页面）
  final Widget child;

  /// 玻璃层可选配置。由 RootPage 从 GameProvider.glassOverlayPrefs 传入；null 时使用默认。
  final GlassOverlayPrefs? glassOverlayConfig;

  const OtokitResponsiveShell({
    super.key,
    required this.child,
    this.glassOverlayConfig,
  });

  @override
  State<OtokitResponsiveShell> createState() => _OtokitResponsiveShellState();
}

class _OtokitResponsiveShellState extends State<OtokitResponsiveShell> {
  TabletSidebarController? _tabletController;

  TabletSidebarController _getOrCreateTabletController() {
    _tabletController ??= TabletSidebarController();
    return _tabletController!;
  }

  @override
  void dispose() {
    _tabletController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final analysis = analyzeLayout(
      widthDp: mq.size.width,
      displayFeatures: mq.displayFeatures,
    );

    // 【平板 vs 手机】唯一分支：compact=手机路径，否则=平板路径；下游仅消费 ResponsiveLayoutScope。
    final isCompact = analysis.sizeClass == WindowSizeClass.compact;

    final double totalWidth = mq.size.width;
    final int paneCount = _resolvePaneCount(analysis, totalWidth);

    final double primaryWidth;
    if (paneCount == 1) {
      primaryWidth = totalWidth;
    } else if (analysis.topology != DeviceTopology.flat &&
        analysis.hingeBounds.isNotEmpty) {
      primaryWidth = analysis.hingeBounds.first.left;
    } else {
      primaryWidth = totalWidth * _defaultPrimaryRatio;
    }

    return ResponsiveLayoutScope(
      availablePaneCount: paneCount,
      primaryPaneWidth: primaryWidth,
      isCompactNavigation: isCompact,
      child: isCompact
          ? _buildCompactLayout(context, widget.child)
          : _buildExpandedLayout(context, widget.child),
    );
  }

  /// 【手机专属】Compact 布局：悬浮胶囊导航 + 左侧手势热区；不包含任何平板状态或组件。
  Widget _buildCompactLayout(BuildContext context, Widget content) {
    return Stack(
      children: [
        Positioned.fill(child: content),
        _buildEdgeGesture(context),
        _buildActionButtons(context, showMenu: true),
        const Positioned.fill(child: NavDeckOverlay()),
      ],
    );
  }

  /// 【平板专属】Medium+ 布局：平板玻璃层 + 两侧热区 + 侧边栏；状态仅 TabletSidebarController，手机树不可见。
  Widget _buildExpandedLayout(BuildContext context, Widget content) {
    return ChangeNotifierProvider<TabletSidebarController>.value(
      value: _getOrCreateTabletController(),
      child: _TabletExpandedLayout(
        content: content,
        glassOverlayConfig: widget.glassOverlayConfig,
      ),
    );
  }

  /// 左侧 4% 宽手势热区，仅 Compact 模式渲染
  Widget _buildEdgeGesture(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.04,
      child: Consumer<NavigationProvider>(
        builder: (context, nav, _) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) {
              if (details.delta.dx > 5 && !nav.isDeckOpen) {
                nav.openDeck(anchorY: details.globalPosition.dy);
              }
            },
          );
        },
      ),
    );
  }

  /// 右上角操作按钮区
  /// [showMenu] Compact 时显示菜单按钮，Medium+ 时由平板玻璃内设置按钮替代，此处不显示
  Widget _buildActionButtons(BuildContext context, {required bool showMenu}) {
    final themeColor =
        Theme.of(context).extension<AppTheme>()?.basic ?? Colors.white;
    return Positioned(
      top: UiSizes.getTopMarginWithSafeArea(context) + 12.0,
      right: UiSizes.screenEdgeMargin + 12.0,
      child: Consumer<NavigationProvider>(
        builder: (context, nav, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              KitActionCircle(
                icon: Icons.settings,
                color: themeColor,
                onTap: () => nav.openSettings(),
              ),
              if (showMenu) ...[
                const SizedBox(width: UiSizes.spaceS),
                Builder(
                  builder: (btnCtx) => KitActionCircle(
                    icon: Icons.menu_open,
                    color: themeColor,
                    onTap: () {
                      final box = btnCtx.findRenderObject() as RenderBox;
                      final pos = box.localToGlobal(Offset.zero);
                      nav.openDeck(anchorY: pos.dy + box.size.height);
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 【平板专属】平板 expanded 布局：自绘玻璃层（含偏移动画）+ 热区 + 侧边栏 + 设置按钮 + 点击收回。
/// 仅出现在 _buildExpandedLayout 子树，使用 TabletSidebarController，手机路径不包含此类。
class _TabletExpandedLayout extends StatefulWidget {
  final Widget content;
  final GlassOverlayPrefs? glassOverlayConfig;

  const _TabletExpandedLayout({
    required this.content,
    this.glassOverlayConfig,
  });

  @override
  State<_TabletExpandedLayout> createState() => _TabletExpandedLayoutState();
}

class _TabletExpandedLayoutState extends State<_TabletExpandedLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _glassOffsetController;
  late CurvedAnimation _glassOffsetCurve;
  double _startOffsetX = 0.0;
  double _endOffsetX = 0.0;

  /// 收缩时 glass 前段保持不动的比例，与侧边栏文字淡出/宽度开始缩的时间对齐（约 100ms/600ms）
  static const double _glassCollapseHoldStart = 100 / 600;

  void _replaceGlassCurve(Curve curve) {
    _glassOffsetCurve.dispose();
    _glassOffsetCurve = CurvedAnimation(
      parent: _glassOffsetController,
      curve: curve,
    );
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _glassOffsetController = AnimationController(
      vsync: this,
      duration: KitAnimationEngine.expandDuration,
    );
    _glassOffsetCurve = CurvedAnimation(
      parent: _glassOffsetController,
      curve: UiAnimations.curveOut,
    );
  }

  @override
  void dispose() {
    _glassOffsetCurve.dispose();
    _glassOffsetController.dispose();
    super.dispose();
  }

  void _applyGlassOffset(double targetOffsetX, {bool isClosing = false}) {
    final isCollapsing = targetOffsetX == 0.0;
    _startOffsetX =
        _startOffsetX + (_endOffsetX - _startOffsetX) * _glassOffsetCurve.value;
    _endOffsetX = targetOffsetX;
    _glassOffsetController.reset();

    if (isCollapsing) {
      _glassOffsetController.duration = UiAnimations.slow;
      if (isClosing) {
        // 侧边栏滑出视口关闭：glass 立即随动，无前段保持
        _replaceGlassCurve(UiAnimations.curveOut);
      } else {
        // 胶囊收缩：前段与侧边栏文字淡出对齐，避免宽卡片盖住 glass
        _replaceGlassCurve(
          Interval(_glassCollapseHoldStart, 1.0, curve: UiAnimations.curveOut),
        );
      }
      _glassOffsetController.forward();
    } else {
      _glassOffsetController.duration = KitAnimationEngine.expandDuration;
      _replaceGlassCurve(UiAnimations.curveOut);
      _glassOffsetController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 玻璃定位始终用 5% + 安全区；玻璃内组件由 UiSizes.getTopMargin 在平板返回 0 不再叠加
    final mq = MediaQuery.of(context);
    final base = mq.size.height * UiSizes.shellMarginTopMultiplier;
    final safeTop = mq.padding.top;
    final top = safeTop > base ? safeTop + UiSizes.spaceXS : base;

    return Consumer<TabletSidebarController>(
      builder: (context, ctrl, _) {
        double targetOffsetX = 0.0;
        if (ctrl.isOpen && !ctrl.isClosing && ctrl.isExpanded) {
          final expandOffset = _tabletGlassMargin - 2 * _tabletStandardSize;
          targetOffsetX = ctrl.side == 0 ? expandOffset : -expandOffset;
        }
        if (targetOffsetX != _endOffsetX) {
          final isClosing = ctrl.isClosing;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _applyGlassOffset(targetOffsetX, isClosing: isClosing);
          });
        }

        return Stack(
          children: [
            // 1. 玻璃层（含偏移动画）+ 两侧热区（宽度随 offset 收缩，不盖住 glass）
            AnimatedBuilder(
              animation: _glassOffsetCurve,
              builder: (context, _) {
                final offsetX =
                    _startOffsetX +
                    (_endOffsetX - _startOffsetX) * _glassOffsetCurve.value;
                final leftHotWidth =
                    (_tabletGlassMargin + offsetX).clamp(0.0, double.infinity);
                final rightHotWidth =
                    (_tabletGlassMargin - offsetX).clamp(0.0, double.infinity);
                return Stack(
                  children: [
                    Positioned(
                      top: top,
                      left: _tabletGlassMargin + offsetX,
                      right: _tabletGlassMargin - offsetX,
                      bottom: 0,
                      child: _buildTabletGlassChild(
                        context,
                        onBlankTap: (ctrl.isOpen && !ctrl.isClosing)
                            ? () => ctrl.close()
                            : null,
                        glassConfig: widget.glassOverlayConfig,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: leftHotWidth,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => ctrl.open(0),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: rightHotWidth,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => ctrl.open(1),
                      ),
                    ),
                  ],
                );
              },
            ),
            // 2. 侧边栏（leaving + entry）
            if (ctrl.isOpen) ...[
              if (ctrl.leavingSide != null)
                TabletSidebarMinimal(
                  key: ValueKey('leave_${ctrl.leavingSide}'),
                  side: ctrl.leavingSide!,
                  expanded: ctrl.isExpanded,
                  isLeaving: true,
                  onLeaveComplete: ctrl.clearLeaving,
                ),
              TabletSidebarMinimal(
                key: ValueKey('entry_${ctrl.side}'),
                side: ctrl.side,
                expanded: ctrl.isExpanded,
                isLeaving: ctrl.isClosing,
                onLeaveComplete: ctrl.isClosing ? ctrl.finalizeClose : null,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTabletGlassChild(BuildContext context,
      {VoidCallback? onBlankTap, GlassOverlayPrefs? glassConfig}) {
    const borderRadius = BorderRadius.only(
      topLeft: Radius.circular(28.0),
      topRight: Radius.circular(28.0),
    );

    final Widget contentChild = onBlankTap != null
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onBlankTap,
            child: widget.content,
          )
        : widget.content;

    final prefs = glassConfig?.normalized();

    final glassVisual = Stack(
      fit: StackFit.expand,
      children: [
        _buildTabletGlassFillLayer(prefs),
        if (prefs == null || prefs.strokeEnabled)
          CustomPaint(painter: _TabletGlassStrokePainter()),
      ],
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          glassVisual,
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                  child: contentChild,
                );
              },
            ),
          ),
          Positioned(
            top: 12.0,
            right: 12.0,
            child: Consumer<NavigationProvider>(
              builder: (context, nav, _) {
                final themeColor =
                    Theme.of(context).extension<AppTheme>()?.basic ??
                    Colors.white;
                return KitActionCircle(
                  icon: Icons.settings,
                  color: themeColor,
                  onTap: () => nav.openSettings(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const double _blurSigma = 12.0;
  static const double _opacityTop = 0.50;
  static const double _opacityBottom = 0.24;

  Widget _buildTabletGlassFillLayer(GlassOverlayPrefs? prefs) {
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

class _TabletGlassStrokePainter extends CustomPainter {
  _TabletGlassStrokePainter();

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

/// 根据设备拓扑与铰链物理尺寸计算可用 Pane 数量。
///
/// Flat：compact/medium → 1，expanded/large → 2。
/// SingleHinge：两侧区域均 ≥ [_minPaneWidth] 时给 2，否则退让为 1。
/// DualHinge：统计三个物理区中宽度 ≥ [_minPaneWidth] 的区域数，clamp(1, 3)。
int _resolvePaneCount(LayoutAnalysis analysis, double totalWidth) {
  switch (analysis.topology) {
    case DeviceTopology.flat:
      return analysis.sizeClass == WindowSizeClass.compact ||
              analysis.sizeClass == WindowSizeClass.medium
          ? 1
          : 2;

    case DeviceTopology.singleHinge:
      if (analysis.hingeBounds.isEmpty) return 1;
      final hinge = analysis.hingeBounds.first;
      final leftZone = hinge.left;
      final rightZone = totalWidth - hinge.right;
      return leftZone >= _minPaneWidth && rightZone >= _minPaneWidth ? 2 : 1;

    case DeviceTopology.dualHinge:
      if (analysis.hingeBounds.length < 2) return 1;
      final h0 = analysis.hingeBounds[0];
      final h1 = analysis.hingeBounds[1];
      final validCount = [
        h0.left,
        h1.left - h0.right,
        totalWidth - h1.right,
      ].where((z) => z >= _minPaneWidth).length;
      return validCount.clamp(1, 3);
  }
}
