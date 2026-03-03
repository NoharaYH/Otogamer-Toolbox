import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/shared/toast_provider.dart';
import '../constants/colors.dart';
import '../theme/core/app_theme.dart';
import '../constants/sizes.dart';
import '../constants/animations.dart';
import '../kit_shared/kit_bounce_scaler.dart';

class ScoreSyncModeTabs extends StatefulWidget {
  final int mode; // 0: Diving Fish, 1: Both, 2: LXNS
  final ValueChanged<int> onModeChanged;
  final bool isDisabled;
  final bool isDfVerified;
  final bool isLxnsVerified;

  const ScoreSyncModeTabs({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.isDisabled,
    required this.isDfVerified,
    required this.isLxnsVerified,
  });

  @override
  State<ScoreSyncModeTabs> createState() => _ScoreSyncModeTabsState();
}

class _ScoreSyncModeTabsState extends State<ScoreSyncModeTabs>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 从 0 (不脉动) 到 1 (脉动到 0.7)
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDualLockedClick() {
    if (_pulseController.isAnimating) return;
    _pulseController.forward(from: 0.0);

    final toast = context.read<ToastProvider>();
    if (!widget.isDfVerified && !widget.isLxnsVerified) {
      toast.show('请验证水鱼和落雪平台', ToastType.warning);
    } else if (!widget.isDfVerified) {
      toast.show('请验证水鱼平台', ToastType.warning);
    } else if (!widget.isLxnsVerified) {
      toast.show('请验证落雪平台', ToastType.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = Theme.of(context).extension<AppTheme>();
    final Color activeColor = skin?.medium ?? UiColors.grey500;

    return IgnorePointer(
      ignoring: widget.isDisabled,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 150),
        tween: Tween<double>(
          begin: widget.isDisabled ? 1.0 : 0.0,
          end: widget.isDisabled ? 1.0 : 0.0,
        ),
        builder: (context, value, child) {
          return ColorFiltered(
            colorFilter: ColorFilter.mode(
              Color.lerp(UiColors.transparent, UiColors.disabledMask, value)!,
              BlendMode.srcATop,
            ),
            child: child,
          );
        },
        child: Container(
          height: 46,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: UiSizes.atomicComponentGap),
          padding: const EdgeInsets.all(UiSizes.spaceXXS),
          decoration: BoxDecoration(
            color: UiColors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(UiSizes.panelRadius),
          ),
          child: Row(
            children: [
              _buildTab(0, '水鱼', activeColor),
              _buildTab(1, '双平台', activeColor),
              _buildTab(2, '落雪', activeColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String text, Color activeColor) {
    final isSelected = widget.mode == index;
    final isDualTab = index == 1;
    final bool isDualDisabled = !widget.isDfVerified || !widget.isLxnsVerified;
    final bool isThisTabLocked = isDualTab && isDualDisabled;

    return Expanded(
      child: KitBounceScaler(
        onTap: isThisTabLocked
            ? _handleDualLockedClick
            : () => widget.onModeChanged(index),
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            // 基础不透明度：锁定为 0.4，普通为 1.0
            // 脉动时：0.4 -> 0.7 之间波动 (增加 0.3 * pulseValue)
            double baseOpacity = isThisTabLocked ? 0.4 : 1.0;
            if (isThisTabLocked) {
              baseOpacity += _pulseAnimation.value * 0.3;
            }

            return AnimatedOpacity(
              duration: UiAnimations.fast,
              opacity: baseOpacity,
              child: Container(
                margin: const EdgeInsets.all(2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedContainer(
                      duration: UiAnimations.fast,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? UiColors.white
                            : UiColors.transparent,
                        borderRadius: BorderRadius.circular(
                          UiSizes.buttonRadius - 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: UiColors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                    ),
                    Center(
                      child: AnimatedDefaultTextStyle(
                        duration: UiAnimations.fast,
                        style: TextStyle(
                          color: isSelected
                              ? activeColor
                              : UiColors.black.withValues(alpha: 0.54),
                          fontFamily: 'JiangCheng',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        child: Text(text),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
