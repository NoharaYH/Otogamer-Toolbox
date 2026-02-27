import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../visual_skins/skin_extension.dart';
import '../constants/sizes.dart';
import '../constants/animations.dart';

class ScoreSyncModeTabs extends StatelessWidget {
  final int mode; // 0: Diving Fish, 1: Both, 2: LXNS
  final ValueChanged<int> onModeChanged;
  final bool isDisabled;

  const ScoreSyncModeTabs({
    super.key,
    required this.mode,
    required this.onModeChanged,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final skin = Theme.of(context).extension<SkinExtension>();
    final Color activeColor = skin?.dark ?? UiColors.grey500;

    return IgnorePointer(
      ignoring: isDisabled,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 150),
        tween: Tween<double>(
          begin: isDisabled ? 1.0 : 0.0,
          end: isDisabled ? 1.0 : 0.0,
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
            borderRadius: BorderRadius.circular(UiSizes.cardRadius),
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
    final isSelected = mode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedContainer(
                duration: UiAnimations.fast,
                decoration: BoxDecoration(
                  color: isSelected ? UiColors.white : UiColors.transparent,
                  borderRadius: BorderRadius.circular(UiSizes.buttonRadius - 2),
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
      ),
    );
  }
}
