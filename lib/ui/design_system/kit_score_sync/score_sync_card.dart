import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:provider/provider.dart';
import '../../../../application/transfer/transfer_provider.dart';
import '../constants/sizes.dart';
import 'score_sync_mode_tabs.dart';
import '../kit_shared/kit_animation_engine.dart';

/// 成绩同步专用卡片容器
/// 封装了模式切换 Tabs 以及卡片的基础装饰属性
class ScoreSyncCard extends StatelessWidget {
  final int mode;
  final ValueChanged<int> onModeChanged;
  final Widget child;

  const ScoreSyncCard({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferProvider>(
      builder: (context, provider, _) {
        return AnimatedContainer(
          duration: KitAnimationEngine.expandDuration,
          curve: KitAnimationEngine.decelerateCurve,
          width: double.infinity,
          margin: EdgeInsets.only(
            left: UiSizes.spaceS,
            right: UiSizes.spaceS,
            bottom: provider.isTracking
                ? UiSizes.getCardBottomMargin(context)
                : UiSizes.getCardBottomMargin(context),
          ),
          decoration: BoxDecoration(
            color: UiColors.white,
            borderRadius: BorderRadius.circular(UiSizes.cardRadius),
            boxShadow: [
              BoxShadow(
                color: UiColors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UiSizes.cardContentPadding,
              vertical: UiSizes.atomicComponentGap,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScoreSyncModeTabs(
                  mode: mode,
                  onModeChanged: onModeChanged,
                  isDisabled: provider.isTracking,
                  isDfVerified: provider.isDivingFishVerified,
                  isLxnsVerified: provider.isLxnsVerified,
                ),
                // 必须使用 Expanded，否则内部的 Flexible/GridView 将失去高度基准导致 UI 空白
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}
