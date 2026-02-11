import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/ui/design_system/kit_score_sync/game_specific_content.dart';
import 'package:flutter_application_1/kernel/state/toast_provider.dart';

class TransferPageChunithm extends StatelessWidget {
  final Color activeColor;

  const TransferPageChunithm({super.key, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      // Use the new shared component from Design System
      child: ChunithmDifficultySelector(
        activeColor: activeColor,
        onImport: () {
          // TODO: Implement Transfer Logic
          context.read<ToastProvider>().show('开始导入...', ToastType.verifying);
        },
      ),
    );
  }
}
