import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/ui/design_system/kit_score_sync/game_specific_content.dart';
import 'package:flutter_application_1/kernel/state/toast_provider.dart';

class TransferPageMaimaiDx extends StatelessWidget {
  final Color activeColor;

  const TransferPageMaimaiDx({super.key, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    // The parent `TransferContentAnimator` already applies horizontal padding of 16.0.
    // The Tab Selector has a margin of 12 + padding of 4 = 16.0 effective offset for the inner buttons.
    // So by having 0 horizontal padding here, we align perfectly with the inner Tab buttons (16.0 total).
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: MaimaiDifficultySelector(
        activeColor: activeColor,
        onImport: () {
          // TODO: Implement Transfer Logic
          context.read<ToastProvider>().show('开始导入...', ToastType.verifying);
        },
      ),
    );
  }
}
