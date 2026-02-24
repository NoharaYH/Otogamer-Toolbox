import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../application/transfer/transfer_provider.dart';
import '../constants/sizes.dart';
import 'score_sync_mode_tabs.dart';

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
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
          width: double.infinity,
          margin: EdgeInsets.only(
            left: UiSizes.spaceS,
            right: UiSizes.spaceS,
            bottom: UiSizes.getCardBottomMargin(context),
          ),
          decoration: BoxDecoration(
            color: const Color(0xCCFFFFFF),
            borderRadius: BorderRadius.circular(UiSizes.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: provider.isTracking
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                UiSizes.cardContentPadding,
                UiSizes.atomicComponentGap,
                UiSizes.cardContentPadding,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 模式选择 Tabs
                  ScoreSyncModeTabs(mode: mode, onModeChanged: onModeChanged),

                  // 2. 外部注入的内容区域 (Form 或 SuccessView)
                  child,

                  // 3. 底部保底间距 (12px)
                  const SizedBox(height: UiSizes.atomicComponentGap),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
