import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design_system/constants/sizes.dart';
import '../../../design_system/constants/colors.dart';
import '../../../design_system/visual_skins/skin_extension.dart';
import '../../../design_system/visual_skins/implementations/maimai_dx/circle_background.dart';
import '../../../design_system/kit_score_sync/score_sync_card.dart';
import '../../../design_system/kit_score_sync/score_sync_form.dart';
import '../../../design_system/kit_score_sync/score_sync_token_field.dart';
import '../../../design_system/kit_score_sync/sync_log_panel.dart';
import '../../../design_system/kit_score_sync/content_animator.dart';
import '../../../design_system/kit_score_sync/mai_dif_choice.dart';
import '../../../design_system/kit_score_sync/chu_dif_choice.dart';

import '../../../../application/transfer/transfer_provider.dart';
import '../../../../application/shared/toast_provider.dart';

class ScoreSyncAssembly extends StatefulWidget {
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
  State<ScoreSyncAssembly> createState() => _ScoreSyncAssemblyState();
}

class _ScoreSyncAssemblyState extends State<ScoreSyncAssembly> {
  final TextEditingController dfController = TextEditingController();
  final TextEditingController lxnsController = TextEditingController();
  bool _initializedControllers = false;

  @override
  void dispose() {
    dfController.dispose();
    lxnsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferProvider>(
      builder: (context, provider, _) {
        final skin =
            Theme.of(context).extension<SkinExtension>() ?? const MaimaiSkin();

        // 验证逻辑与准备状态
        final needsDf = widget.mode == 0 || widget.mode == 1;
        final needsLxns = widget.mode == 2 || widget.mode == 1;
        final bool isDfReady =
            !needsDf || provider.isDivingFishVerifiedFor(widget.gameType);
        final bool isLxnsReady =
            !needsLxns || provider.isLxnsVerifiedFor(widget.gameType);
        final bool showSuccessPage = isDfReady && isLxnsReady;

        // 初始化控制器
        if (provider.isStorageLoaded && !_initializedControllers) {
          dfController.text = provider.dfToken;
          lxnsController.text = provider.lxnsTokenFor(widget.gameType);
          _initializedControllers = true;
        }

        final isOtherTracking =
            provider.isTracking && provider.trackingGameType != widget.gameType;

        final Widget content = !provider.isStorageLoaded
            ? const SizedBox(width: double.infinity)
            : (showSuccessPage
                  ? _buildSuccessView(context, provider, skin)
                  : _buildFormView(context, provider, isOtherTracking));

        return ScoreSyncCard(
          key: ValueKey('Card_${widget.gameType}'),
          mode: widget.mode,
          onModeChanged: widget.onModeChanged,
          child: Column(
            children: [
              // 必须 Expanded 这里的动画器，否则在 success 页面它不知道有多高，导致内容空白
              Expanded(child: TransferContentAnimator(child: content)),
            ],
          ),
        );
      },
    );
  }

  final GlobalKey<ScoreSyncTokenFieldState> lxnsFieldKey =
      GlobalKey<ScoreSyncTokenFieldState>();

  Widget _buildFormView(
    BuildContext context,
    TransferProvider provider,
    bool isOtherTracking,
  ) {
    return ScoreSyncForm(
      key: ValueKey('Form_${widget.gameType}_${widget.mode}'),
      mode: widget.mode,
      dfController: dfController,
      lxnsController: lxnsController,
      isLoading: provider.isLoading,
      isDisabled: isOtherTracking,
      isLxnsOAuthDone: provider.isLxnsOAuthDoneFor(widget.gameType),
      lxnsFieldKey: lxnsFieldKey,
      onVerify: () => _handleVerify(context, provider, widget.mode),
      onDfChanged: () =>
          provider.resetVerification(gameType: widget.gameType, df: true),
      onLxnsChanged: () =>
          provider.resetVerification(gameType: widget.gameType, lxns: true),
      onDfPaste: (text) {
        dfController.text = text;
        provider.resetVerification(gameType: widget.gameType, df: true);
      },
      onLxnsPaste: (text) {
        lxnsController.text = text;
        provider.resetVerification(gameType: widget.gameType, lxns: true);
      },
      onLxnsOAuth: () => provider.startLxnsOAuthFlow(gameType: widget.gameType),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    TransferProvider provider,
    SkinExtension skin,
  ) {
    final isCurrentTracking =
        provider.isTracking && provider.trackingGameType == widget.gameType;
    final isOtherTracking =
        provider.isTracking && provider.trackingGameType != widget.gameType;

    return Column(
      key: ValueKey<String>('Success_${widget.gameType}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.gameType == 0 ? "选择导入难度" : "中二传分设置",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: UiColors.grey800,
            fontFamily: 'JiangCheng',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Container(
          height: 1,
          color: UiColors.grey500.withValues(alpha: 0.3),
          margin: const EdgeInsets.symmetric(
            vertical: UiSizes.atomicComponentGap,
          ),
        ),
        if (widget.gameType == 0)
          MaiDifChoice(
            isLoading: isCurrentTracking,
            isDisabled: isOtherTracking,
            onImport: (diffs) {
              provider.startImport(
                gameType: widget.gameType,
                mode: widget.mode,
                difficulties: diffs,
              );
            },
          )
        else
          ChuDifChoice(
            isLoading: isCurrentTracking,
            isDisabled: isOtherTracking,
            onImport: (diffs) {
              provider.startImport(
                gameType: widget.gameType,
                mode: widget.mode,
                difficulties: diffs,
              );
            },
          ),
        const SizedBox(height: UiSizes.spaceS),
        // 日志面板展开时填满卡片剩余空间，触底由外部卡片 margin 保证
        Expanded(
          child: SyncLogPanel(
            key: ValueKey('Log_${widget.gameType}'),
            logs: provider.getVpnLog(widget.gameType),
            isTracking: isCurrentTracking,
            estimatedUsedHeight: widget.gameType == 0
                ? UiSizes.scoreSyncUsedHeightMai
                : UiSizes.scoreSyncUsedHeightLxns,
            onCopy: () {
              final currentLogs = provider.getVpnLog(widget.gameType);
              Clipboard.setData(ClipboardData(text: currentLogs));
              provider.appendLog('[COPY]已将控制台内容复制到剪切板');
            },
            onClose: () => provider.stopVpn(isManually: true),
            onConfirmPause: () => provider.appendLog('[PAUSE]传分业务已暂停'),
            onConfirmResume: () => provider.appendLog('[RESUME]传分业务继续'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleVerify(
    BuildContext context,
    TransferProvider provider,
    int mode,
  ) async {
    final dfToken = dfController.text.trim();
    final lxnsToken = lxnsController.text.trim();

    // UI状态打包下沉给中枢：用户敲击结束后，确认执行那刻才提交数据
    provider.updateTokens(
      gameType: widget.gameType,
      df: dfToken,
      lxns: lxnsToken,
    );

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
    final success = await provider.verifyAndSave(
      mode: mode,
      gameType: widget.gameType,
    );

    if (!mounted) return;

    if (success) {
      if (!context.mounted) return;
      context.read<ToastProvider>().show(
        provider.successMessage ?? '验证通过',
        ToastType.confirmed,
      );
    } else if (provider.errorMessage != null) {
      if (!context.mounted) return;
      context.read<ToastProvider>().show(
        provider.errorMessage!,
        ToastType.error,
      );
    }
  }
}
