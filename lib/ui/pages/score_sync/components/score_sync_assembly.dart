import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design_system/constants/sizes.dart';
import '../../../design_system/visual_skins/skin_extension.dart';
import '../../../design_system/visual_skins/implementations/maimai_dx/circle_background.dart';
import '../../../design_system/kit_score_sync/score_sync_card.dart';
import '../../../design_system/kit_score_sync/score_sync_form.dart';
import '../../../design_system/kit_score_sync/sync_log_panel.dart';
import '../../../design_system/kit_score_sync/content_animator.dart';
import '../../../design_system/kit_shared/confirm_button.dart';
import '../../../design_system/kit_score_sync/mai_dif_choice.dart';

import '../../../../application/transfer/transfer_provider.dart';
import '../../../../application/shared/toast_provider.dart';

class ScoreSyncAssembly extends StatelessWidget {
  final int mode;
  final ValueChanged<int> onModeChanged;
  final int gameType;

  const ScoreSyncAssembly({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.gameType,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferProvider>(
      builder: (context, provider, _) {
        final skin =
            Theme.of(context).extension<SkinExtension>() ?? const MaimaiSkin();

        // 验证逻辑与准备状态
        final needsDf = mode == 0 || mode == 1;
        final needsLxns = mode == 2 || mode == 1;
        final bool isDfReady = !needsDf || provider.isDivingFishVerified;
        final bool isLxnsReady = !needsLxns || provider.isLxnsVerified;
        final bool showSuccessPage = isDfReady && isLxnsReady;

        final Widget content = !provider.isStorageLoaded
            ? const SizedBox(width: double.infinity)
            : (showSuccessPage
                  ? _buildSuccessView(context, provider, skin)
                  : _buildFormView(context, provider));

        return ScoreSyncCard(
          mode: mode,
          onModeChanged: onModeChanged,
          child: Column(
            children: [
              // 内容动画器切换
              TransferContentAnimator(child: content),

              // 日志面板管理
              SyncLogPanel(
                logs: provider.vpnLog,
                forceHidden:
                    !provider.isTracking ||
                    provider.trackingGameType != gameType,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: provider.vpnLog));
                  context.read<ToastProvider>().show(
                    "已复制日志",
                    ToastType.confirmed,
                  );
                },
                onClose: () => provider.stopTracking(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormView(BuildContext context, TransferProvider provider) {
    return ScoreSyncForm(
      key: ValueKey<int>(mode),
      mode: mode,
      dfController: provider.dfController,
      lxnsController: provider.lxnsController,
      isLoading: provider.isLoading,
      onVerify: () => _handleVerify(context, provider, mode),
      onDfChanged: () => provider.resetVerification(df: true),
      onLxnsChanged: () => provider.resetVerification(lxns: true),
      onDfPaste: (text) => provider.handlePaste(text, isDf: true),
      onLxnsPaste: (text) => provider.handlePaste(text, isDf: false),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    TransferProvider provider,
    SkinExtension skin,
  ) {
    return Column(
      key: ValueKey<String>('Success_$gameType'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                gameType == 0 ? "选择导入难度" : "中二传分设置",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ConfirmButton(
              text: "返回token填写",
              fontSize: 11,
              padding: const EdgeInsets.symmetric(
                horizontal: UiSizes.spaceXS,
                vertical: UiSizes.spaceXXS,
              ),
              onPressed: () {
                provider.resetVerification(df: true, lxns: true);
              },
            ),
          ],
        ),
        if (gameType == 0)
          Container(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.3),
            margin: const EdgeInsets.symmetric(
              vertical: UiSizes.atomicComponentGap,
            ),
          ),
        if (gameType == 0)
          MaiDifChoice(
            activeColor: skin.medium,
            onImport: (diffs) {
              provider.startImport(gameType: gameType, difficulties: diffs);
              context.read<ToastProvider>().show(
                '正在初始化环境...',
                ToastType.verifying,
              );
            },
          )
        else
          ChuDifChoice(
            activeColor: skin.medium,
            onImport: (diffs) {
              provider.startImport(gameType: gameType, difficulties: diffs);
              context.read<ToastProvider>().show(
                '正在初始化环境...',
                ToastType.verifying,
              );
            },
          ),
      ],
    );
  }

  Future<void> _handleVerify(
    BuildContext context,
    TransferProvider provider,
    int mode,
  ) async {
    final dfToken = provider.dfController.text.trim();
    final lxnsToken = provider.lxnsController.text.trim();

    final needsDf = mode == 0 || mode == 1;
    final needsLxns = mode == 2 || mode == 1;

    if (needsDf && dfToken.isEmpty) {
      context.read<ToastProvider>().show('请输入水鱼查分Token', ToastType.error);
      return;
    }
    if (needsLxns && lxnsToken.isEmpty) {
      context.read<ToastProvider>().show('请输入落雪API密钥', ToastType.error);
      return;
    }

    context.read<ToastProvider>().show('验证中', ToastType.verifying);
    final success = await provider.verifyAndSave(mode: mode);

    if (success) {
      context.read<ToastProvider>().show(
        provider.successMessage ?? '验证通过',
        ToastType.confirmed,
      );
    } else if (provider.errorMessage != null) {
      context.read<ToastProvider>().show(
        provider.errorMessage!,
        ToastType.error,
      );
    }
  }
}
