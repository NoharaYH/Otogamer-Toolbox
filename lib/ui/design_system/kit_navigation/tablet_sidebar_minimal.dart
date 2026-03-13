import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/shared/navigation_provider.dart';
import '../constants/animations.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../kit_shared/kit_animation_engine.dart';
import 'kit_nav_capsule.dart';
import 'tablet_sidebar_controller.dart';

// Private constants for tablet sidebar (not in global UiSizes).
const double _capGap = 14.4;
const double _capSize = 55.2;
const double _minimalWidth = 72.0;
const double _navCapsuleMaxWidthWithText = 166.0;
const double _tabletStandardSize = 24.0;
double get _expandedWidth =>
    _navCapsuleMaxWidthWithText + _tabletStandardSize + 8.0;

/// 【架构红线·平板专属组件】平板侧边栏（无全局阴影）。
/// 仅由 OtokitResponsiveShell._buildExpandedLayout 挂载，Compact 路径永不使用此组件。
///
/// 布局结构：
///   ├── [Expanded] Nav 区：所有功能页按钮，垂直居中
///   │     • _TabletNavItem 实现圆→带字胶囊变形动画
///   └── [固定底部] 设置 + 展开/收起按钮（KitNavCapsule isCircle: true）
///
/// 动画规格：
///   • 滑入/滑出：UiAnimations.slow(600ms) + easeOutQuart
///   • 展开/收缩：与 KitAnimationEngine 一致，四段相位
class TabletSidebarMinimal extends StatefulWidget {
  /// 0=左侧 1=右侧
  final int side;

  /// 当前是否处于展开态
  final bool expanded;

  /// 是否为切换侧时正在滑出的一侧
  final bool isLeaving;

  /// 滑出动画结束时调用（仅 isLeaving 时使用）
  final VoidCallback? onLeaveComplete;

  const TabletSidebarMinimal({
    super.key,
    required this.side,
    required this.expanded,
    this.isLeaving = false,
    this.onLeaveComplete,
  });

  @override
  State<TabletSidebarMinimal> createState() => _TabletSidebarMinimalState();
}

class _TabletSidebarMinimalState extends State<TabletSidebarMinimal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _expandController;
  late CurvedAnimation _slideCurve;
  late CurvedAnimation _expandCurve;
  late Animation<double> _slideAnimation;

  late double _slideOffset;

  static Duration get _expandDuration => KitAnimationEngine.expandDuration;
  static Duration get _collapseDuration => KitAnimationEngine.expandDuration;

  static const int _expandWidthMs = 500;
  static const int _expandTextMs = 100;
  static const int _collapseTextMs = 100;
  static const int _collapseWidthMs = 500;

  double get _expandWidthRatio =>
      _expandWidthMs / (_expandWidthMs + _expandTextMs);
  double get _collapseTextRatio =>
      _collapseTextMs / (_collapseTextMs + _collapseWidthMs);

  double _widthPhase(double v, bool isReversing) {
    final curve = UiAnimations.curveOut;
    if (isReversing) {
      final r = 1 - _collapseTextRatio;
      if (v > r) return 1.0;
      final progress = (r - v) / r;
      return 1.0 - curve.transform(progress.clamp(0.0, 1.0));
    }
    if (v > _expandWidthRatio) return 1.0;
    final linear = (v / _expandWidthRatio).clamp(0.0, 1.0);
    return curve.transform(linear);
  }

  double _textPhase(double v, bool isReversing) {
    final curve = UiAnimations.curveOut;
    if (isReversing) {
      final r = 1 - _collapseTextRatio;
      if (v <= r) return 0.0;
      final progress = (1.0 - v) / _collapseTextRatio;
      return 1.0 - curve.transform(progress.clamp(0.0, 1.0));
    }
    if (v < _expandWidthRatio) return 0.0;
    final linear = ((v - _expandWidthRatio) / (1.0 - _expandWidthRatio))
        .clamp(0.0, 1.0);
    return curve.transform(linear);
  }

  bool get _isReversing =>
      _expandController.status == AnimationStatus.reverse;

  @override
  void initState() {
    super.initState();

    final initWidth = widget.expanded ? _expandedWidth : _minimalWidth;
    _slideOffset = -(initWidth + _tabletStandardSize + 30.0);

    _slideController = AnimationController(
      vsync: this,
      duration: UiAnimations.slow,
    );
    _expandController = AnimationController(
      vsync: this,
      duration: _expandDuration,
      reverseDuration: _collapseDuration,
    );

    _slideCurve = CurvedAnimation(
      parent: _slideController,
      curve: UiAnimations.curveOut,
    );
    _expandCurve = CurvedAnimation(
      parent: _expandController,
      curve: UiAnimations.curveOut,
      reverseCurve: UiAnimations.curveOut,
    );

    if (widget.isLeaving) {
      _slideAnimation = Tween<double>(
        begin: 0.0,
        end: _slideOffset,
      ).animate(_slideCurve);
      _slideController.addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onLeaveComplete?.call();
      });
    } else {
      _slideAnimation = Tween<double>(
        begin: _slideOffset,
        end: 0.0,
      ).animate(_slideCurve);
    }
    _slideController.forward();
    _expandController.value = widget.expanded ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(covariant TabletSidebarMinimal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      if (widget.expanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
    if (!oldWidget.isLeaving && widget.isLeaving) {
      final rawV = _expandController.value;
      final widthT = _widthPhase(rawV, _isReversing);
      final currentVisualWidth =
          _minimalWidth + (_expandedWidth - _minimalWidth) * widthT;
      _slideOffset = -(currentVisualWidth + _tabletStandardSize + 30.0);
      final currentPos = _slideAnimation.value;
      _slideAnimation = Tween<double>(
        begin: currentPos,
        end: _slideOffset,
      ).animate(_slideCurve);
      _slideController.addStatusListener(_onLeaveAnimationStatus);
      _slideController.reset();
      _slideController.forward();
    }
  }

  void _onLeaveAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onLeaveComplete?.call();
    }
  }

  @override
  void dispose() {
    _slideCurve.dispose();
    _expandCurve.dispose();
    _slideController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  static List<_NavItemData> get _navItems => [
        _NavItemData(
          PageTag.scoreSync,
          Icons.sync,
          UiStrings.navScoreSync,
          'score data sync',
          Colors.green,
        ),
        _NavItemData(
          PageTag.musicData,
          Icons.library_music,
          UiStrings.navMusicData,
          'music data base',
          Colors.blue,
        ),
        _NavItemData(
          null,
          Icons.more_horiz,
          UiStrings.navComingSoon,
          'coming soon',
          Colors.grey,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.side == 0;

    return Consumer<TabletSidebarController>(
      builder: (context, ctrl, _) {
        if (!ctrl.isOpen && !widget.isLeaving) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: Listenable.merge([
            _slideCurve,
            _expandCurve,
            _expandController,
          ]),
          builder: (context, _) {
            final rawV = _expandController.value.clamp(0.0, 1.0);
            final widthT = _widthPhase(rawV, _isReversing);
            final width =
                _minimalWidth + (_expandedWidth - _minimalWidth) * widthT;

            return Positioned(
              left: isLeft ? _tabletStandardSize + _slideAnimation.value : null,
              right: isLeft ? null : _tabletStandardSize + _slideAnimation.value,
              top: 0,
              bottom: 0,
              width: width,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: isLeft
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: _buildNavArea(context, rawV, width, widthT, isLeft),
                      ),
                    ),
                    Align(
                      alignment: isLeft
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: _buildBottomButtons(context, rawV),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavArea(
    BuildContext context,
    double rawV,
    double containerWidth,
    double widthT,
    bool isLeft,
  ) {
    final nav = context.read<NavigationProvider>();
    final items = _navItems;
    final cw = containerWidth.isFinite ? containerWidth : _expandedWidth;
    final rawWidth = (_capSize + (cw - _capSize) * widthT).clamp(_capSize, cw);
    final animatedWidth = rawWidth < _capSize + 0.25
        ? _capSize
        : math.max(_capSize, rawWidth.truncate().toDouble() - 1.0);
    final textT = _textPhase(rawV.clamp(0.0, 1.0), _isReversing);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(items.length * 2 - 1, (i) {
        if (i.isOdd) return const SizedBox(height: _capGap);
        final item = items[i ~/ 2];
        return SizedBox(
          width: animatedWidth,
          height: _capSize,
          child: _TabletNavItem(
            icon: item.icon,
            label: item.label,
            subLabel: item.subLabel,
            color: item.color,
            isSelected: item.tag != null && nav.currentTag == item.tag,
            onTap: () {
              if (item.tag != null) nav.switchTo(item.tag!);
            },
            width: animatedWidth,
            labelOpacity: textT,
          ),
        );
      }),
    );
  }

  Widget _buildBottomButtons(BuildContext context, double rawV) {
    final ctrl = context.read<TabletSidebarController>();
    final nav = context.read<NavigationProvider>();
    final isExpanded = rawV > 0.5;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KitNavCapsule(
          icon: Icons.close,
          isCircle: true,
          onTap: () => ctrl.close(),
          isSelected: false,
        ),
        const SizedBox(height: 12.0),
        KitNavCapsule(
          icon: Icons.settings,
          isCircle: true,
          onTap: () => nav.openSettings(),
          isSelected: false,
        ),
        const SizedBox(height: 12.0),
        Transform.rotate(
          angle: math.pi / 2,
          child: KitNavCapsule(
            icon: isExpanded ? Icons.unfold_less : Icons.unfold_more,
            isCircle: true,
            onTap: () =>
                isExpanded ? ctrl.collapse() : ctrl.expand(),
            isSelected: false,
          ),
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }
}

/// 平板侧边栏内导航项：圆→带字胶囊变形，不依赖 KitNavCapsule 额外参数。
/// Row 仅保留 icon 为固定宽度，其余放入 Flexible，任意动画曲线下均不溢出。
class _TabletNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double labelOpacity;

  const _TabletNavItem({
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.width,
    required this.labelOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final basicColor = color;
    final contentColor =
        isSelected ? basicColor : basicColor.withValues(alpha: 0.6);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: UiAnimations.fast,
        curve: Curves.easeOutCubic,
        height: _capSize,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8.4, vertical: 8.4),
        decoration: BoxDecoration(
          color: UiColors.white,
          borderRadius: BorderRadius.circular(_capSize / 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 16.0,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            if (isSelected)
              BoxShadow(
                color: basicColor.withValues(alpha: 0.2),
                blurRadius: 10.0,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38.4,
              height: 38.4,
              decoration: BoxDecoration(
                color: basicColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: UiColors.white,
                size: 21.6,
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 9.6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: labelOpacity.clamp(0.0, 1.0),
                    child: SizedBox(
                      height: 38.4,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (subLabel.isNotEmpty)
                            SizedBox(
                              height: 13.2,
                              child: Text(
                                subLabel,
                                style: TextStyle(
                                  fontFamily: 'JiangCheng',
                                  color: contentColor,
                                  fontSize: 13.2,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          SizedBox(
                            height: 19.2,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'JiangCheng',
                                color: contentColor,
                                fontSize: 19.2,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final PageTag? tag;
  final IconData icon;
  final String label;
  final String subLabel;
  final Color color;
  _NavItemData(this.tag, this.icon, this.label, this.subLabel, this.color);
}
