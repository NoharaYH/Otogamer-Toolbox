import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../kernel/state/transfer_provider.dart';
import '../../../../kernel/state/toast_provider.dart';

import '../../../../ui/design_system/visual_skins/skin_extension.dart';
import '../../../../ui/design_system/visual_skins/implementations/maimai_dx/circle_background.dart';
import '../../../../ui/design_system/constants/sizes.dart';
import '../../../../ui/design_system/kit_score_sync/content_animator.dart';
import '../../../../ui/design_system/kit_shared/confirm_button.dart';
import 'transfer_page_maimaidx.dart';
import 'transfer_page_chunithm.dart';

// Note: Ensure Animator is accessible. It was moved to ui/kit/components/molecules.

class TransferModeCard extends StatefulWidget {
  final int mode; // 0: Diving Fish, 1: Both, 2: LXNS
  final ValueChanged<int> onModeChanged;
  final int gameType; // 0: Maimai, 1: Chunithm

  const TransferModeCard({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.gameType,
  });

  @override
  State<TransferModeCard> createState() => _TransferModeCardState();
}

class _TransferModeCardState extends State<TransferModeCard> {
  // Local UI state for visibility toggles
  bool _showDfToken = false;
  bool _showLxnsToken = false;

  String? _pendingClipboardDf;
  String? _pendingClipboardLxns;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(TransferModeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Removed automatic verification reset on mode switch to persist state
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access theme via ThemeExtension
    final skin = Theme.of(context).extension<SkinExtension>() ?? MaimaiSkin();

    return Consumer<TransferProvider>(
      builder: (context, provider, child) {
        // Validation Logic from Provider
        final needsDf = widget.mode == 0 || widget.mode == 1;
        final needsLxns = widget.mode == 2 || widget.mode == 1;

        // Check readiness based on provider state
        final bool isDfReady = !needsDf || provider.isDivingFishVerified;
        final bool isLxnsReady = !needsLxns || provider.isLxnsVerified;
        final bool showSuccessPage = isDfReady && isLxnsReady;

        // ANIMATION CONTROL:
        // If storage hasn't loaded (startup), show an empty container.
        // This creates the "collapsed" state initially.
        // When loaded, the child changes to Input/Success view, triggering the animator.
        final Widget content = !provider.isStorageLoaded
            ? const SizedBox(width: double.infinity) // Collapsed state
            : (showSuccessPage
                  ? _buildSuccessView(provider, skin)
                  : _buildInputView(provider, needsDf, needsLxns, skin));

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(
            horizontal: UiSizes.defaultPadding,
          ),
          decoration: BoxDecoration(
            color: const Color(0xCCFFFFFF),
            borderRadius: BorderRadius.circular(UiSizes.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tab Selector
              Container(
                height: 50,
                margin: const EdgeInsets.all(UiSizes.cardInnerPadding),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: skin.medium.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _buildModeTab(0, '水鱼', skin),
                    _buildModeTab(1, '双平台', skin),
                    _buildModeTab(2, '落雪', skin),
                  ],
                ),
              ),

              // Content Area
              TransferContentAnimator(
                duration: UiSizes.defaultAnimationDuration,
                child: content,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuccessView(TransferProvider provider, SkinExtension skin) {
    return Column(
      key: ValueKey<String>('Success_${widget.gameType}'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.gameType == 0 ? "选择导入难度" : "中二传分设置",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              ConfirmButton(
                text: "返回token填写",
                fontSize: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                onPressed: () {
                  provider.resetVerification(df: true, lxns: true);
                },
              ),
            ],
          ),
        ),
        if (widget.gameType == 0)
          Container(
            height: 1,
            color: const Color(0xFF7B7B7B),
            margin: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          ),
        widget.gameType == 0
            ? TransferPageMaimaiDx(activeColor: skin.medium)
            : TransferPageChunithm(activeColor: skin.medium),
        const SizedBox(height: 16),
        if (widget.gameType == 0) ...[
          ConfirmButton(
            text: provider.isVpnRunning ? "停止捕获" : "开始捕获并上传",
            onPressed: () {
              if (provider.isVpnRunning) {
                provider.stopVpn();
              } else {
                provider.startVpn();
              }
            },
          ),
          if (provider.vpnLog.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              height: 100,
              width: double.infinity,
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  provider.vpnLog,
                  style: const TextStyle(
                    fontFamily: "monospace",
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputView(
    TransferProvider provider,
    bool needsDf,
    bool needsLxns,
    SkinExtension skin,
  ) {
    return Column(
      key: ValueKey<int>(widget.mode),
      children: [
        const SizedBox(height: 8),
        if (needsDf)
          _buildTokenField(
            controller: provider.dfController,
            hint: '请输入水鱼成绩导入Token',
            showToken: _showDfToken,
            onToggleShow: (v) => setState(() => _showDfToken = v),
            isDf: true,
            provider: provider,
          ),
        if (needsLxns)
          _buildTokenField(
            controller: provider.lxnsController,
            hint: '请输入落雪个人API密钥',
            showToken: _showLxnsToken,
            onToggleShow: (v) => setState(() => _showLxnsToken = v),
            isDf: false,
            provider: provider,
          ),
        const SizedBox(height: 4),
        ConfirmButton(
          text: '验证并保存Token',
          state: provider.isLoading
              ? ConfirmButtonState.loading
              : ConfirmButtonState.ready,
          onPressed: () async {
            // 1. 获取当前输入内容（去除首尾空格）
            final dfToken = provider.dfController.text.trim();
            final lxnsToken = provider.lxnsController.text.trim();

            // 2. 预检查：根据当前模式判断是否为空
            //    如果为空，直接提示错误，不触发 loading，不调用 Provider
            bool isInputEmpty = false;
            String? emptyErrorMsg;

            final needsDf = widget.mode == 0 || widget.mode == 1;
            final needsLxns = widget.mode == 2 || widget.mode == 1;

            if (needsDf && dfToken.isEmpty) {
              isInputEmpty = true;
              emptyErrorMsg = '请输入水鱼查分Token';
            } else if (needsLxns && lxnsToken.isEmpty) {
              isInputEmpty = true;
              emptyErrorMsg = '请输入落雪API密钥';
            }

            // 分支 A：输入为空 -> 仅提示，不加载
            if (isInputEmpty) {
              context.read<ToastProvider>().show(
                emptyErrorMsg ?? '请输入Token',
                ToastType.error,
              );
              return;
            }

            // 分支 B：输入有效 -> 触发加载 -> 调用 Provider 验证
            // 注意：Provider 内部即将设置 isLoading = true，UI 会自动重建为 Loading 状态
            context.read<ToastProvider>().show('验证中', ToastType.verifying);

            // 执行验证（等待 Provider 完成）
            // Provider 的 verifyAndSave 方法内会处理 isLoading 的 true/false 切换
            final success = await provider.verifyAndSave(mode: widget.mode);

            if (!mounted) return;

            // 验证完成后的反馈
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
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTokenField({
    required TextEditingController controller,
    required String hint,
    required bool showToken,
    required ValueChanged<bool> onToggleShow,
    required bool isDf,
    required TransferProvider provider,
  }) {
    final hasContent = controller.text.isNotEmpty;
    final bgColor = hasContent ? Colors.grey[100] : Colors.grey[300];
    final pendingClipboard = isDf ? _pendingClipboardDf : _pendingClipboardLxns;

    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            if (!hasContent) {
              await _handlePasteWithConfirmation(context, provider, isDf);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.only(
              left: 12,
              top: 4,
              bottom: 4,
              right: 4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: !showToken,
                    onChanged: (_) {
                      // Reset specific verify status
                      if (isDf) {
                        provider.resetVerification(df: true);
                        setState(() => _pendingClipboardDf = null);
                      } else {
                        provider.resetVerification(lxns: true);
                        setState(() => _pendingClipboardLxns = null);
                      }
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                  child: GestureDetector(
                    onTap: () => onToggleShow(!showToken),
                    child: Icon(
                      showToken ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
                if (hasContent)
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        controller.clear();
                        if (isDf) {
                          provider.resetVerification(df: true);
                          setState(() => _pendingClipboardDf = null);
                        } else {
                          provider.resetVerification(lxns: true);
                          setState(() => _pendingClipboardLxns = null);
                        }
                      },
                      child: const Icon(
                        Icons.cancel,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: GestureDetector(
                      onTap: () async {
                        await _handlePasteWithConfirmation(
                          context,
                          provider,
                          isDf,
                        );
                      },
                      child: const Icon(
                        Icons.content_paste,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: <Widget>[...previousChildren, ?currentChild],
            );
          },
          transitionBuilder: (child, animation) {
            if (child.key == const ValueKey('empty_clipboard')) {
              return child;
            }
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.4, 1.0),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: pendingClipboard != null
              ? KeyedSubtree(
                  key: ValueKey(
                    'paste_box_${isDf ? "df" : "lxns"}_$pendingClipboard',
                  ),
                  child: _buildPasteConfirmBoxContent(
                    pendingClipboard,
                    isDf,
                    provider,
                    showToken,
                  ),
                )
              : const SizedBox(
                  key: ValueKey('empty_clipboard'),
                  width: double.infinity,
                  height: 0,
                ),
        ),
      ],
    );
  }

  Future<void> _handlePasteWithConfirmation(
    BuildContext context,
    TransferProvider provider,
    bool isDf,
  ) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      if (!context.mounted) return;
      setState(() {
        if (isDf) {
          _pendingClipboardDf = text;
        } else {
          _pendingClipboardLxns = text;
        }
      });
    }
  }

  Widget _buildPasteConfirmBoxContent(
    String text,
    bool isDf,
    TransferProvider provider,
    bool showToken,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 文字显示区域：左侧 3/4
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '是否要粘贴以下内容？',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                showToken ? text : '•' * text.length.clamp(0, 20),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                maxLines: 1,
                // 仅在显示明文时使用省略号，隐藏状态（圆点）直接截断不显示省略号
                overflow: showToken ? TextOverflow.ellipsis : TextOverflow.clip,
              ),
            ],
          ),
        ),
        // 按钮区域：右侧 1/4
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isDf) {
                      _pendingClipboardDf = null;
                    } else {
                      _pendingClipboardLxns = null;
                    }
                  });
                  provider.handlePaste(text, isDf: isDf);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isDf) {
                      _pendingClipboardDf = null;
                    } else {
                      _pendingClipboardLxns = null;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeTab(int index, String text, SkinExtension skin) {
    final isSelected = widget.mode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onModeChanged(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 背景层 - 平滑过渡，无淡入淡出
              AnimatedContainer(
                duration: UiSizes.shortAnimationDuration,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
              ),
              // 文字层 - 颜色平滑过渡
              Center(
                child: AnimatedDefaultTextStyle(
                  duration: UiSizes.shortAnimationDuration,
                  style: TextStyle(
                    color: isSelected ? skin.medium : Colors.white,
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
