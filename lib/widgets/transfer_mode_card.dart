import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/transfer_provider.dart';
import 'transfer_page_maimaidx.dart';
import 'transfer_page_chunithm.dart';

class TransferModeCard extends StatefulWidget {
  final Color baseColor;
  final Color borderColor;
  final Color shadowColor;
  final Color containerColor;
  final Color activeColor;
  final Color gradientColor;
  final int mode; // 0: 水鱼, 1: 双平台, 2: LXNS
  final ValueChanged<int> onModeChanged;
  final int gameType; // 0: Maimai, 1: Chunithm

  const TransferModeCard({
    super.key,
    required this.baseColor,
    required this.borderColor,
    required this.shadowColor,
    required this.containerColor,
    required this.activeColor,
    required this.gradientColor,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TransferProvider>(
      builder: (context, provider, child) {
        // Validation Logic from Provider
        final needsDf = widget.mode == 0 || widget.mode == 1;
        final needsLxns = widget.mode == 2 || widget.mode == 1;

        // Check readiness based on provider state
        final bool isDfReady = !needsDf || provider.isDivingFishVerified;
        final bool isLxnsReady = !needsLxns || provider.isLxnsVerified;
        final bool showSuccessPage = isDfReady && isLxnsReady;

        // Listen for side effects (SnackBar)
        // Note: Ideally side effects are handled by a listener, but checks during build are okay for simple UI switches
        if (provider.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
            // Clear error immediately to avoid loop
            // provider.resetVerification(); // Careful with loop here, better handled in simple listener or separate method
          });
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tab Selector
              Container(
                height: 50,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.containerColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _buildModeTab(0, '水鱼'),
                    _buildModeTab(1, '双平台'),
                    _buildModeTab(2, '落雪'),
                  ],
                ),
              ),

              // Content Area
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    reverseDuration: const Duration(milliseconds: 100),
                    switchInCurve: const Interval(
                      0.4,
                      1.0,
                      curve: Curves.easeOut,
                    ),
                    switchOutCurve: Curves.easeIn,
                    child: showSuccessPage
                        ? _buildSuccessView(provider)
                        : _buildInputView(provider, needsDf, needsLxns),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuccessView(TransferProvider provider) {
    return Column(
      key: ValueKey<String>('Success_${widget.gameType}'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.gameType == 0 ? "舞萌传分设置" : "中二传分设置",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () {
                    provider.resetVerification(df: true, lxns: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.activeColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text(
                    "返回token填写",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        widget.gameType == 0
            ? const TransferPageMaimaiDx()
            : const TransferPageChunithm(),
      ],
    );
  }

  Widget _buildInputView(
    TransferProvider provider,
    bool needsDf,
    bool needsLxns,
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
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    bool success = await provider.verifyAndSave(
                      mode: widget.mode,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.successMessage ?? '验证通过'),
                          backgroundColor: widget.activeColor,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    } else if (provider.errorMessage != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.errorMessage!),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.activeColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '验证并保存Token',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
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

    return GestureDetector(
      onTap: () async {
        if (!hasContent) {
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          if (data?.text?.isNotEmpty ?? false) {
            provider.handlePaste(data!.text!, isDf: isDf);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: !showToken,
                onChanged: (_) {
                  // Reset specific verify status
                  if (isDf)
                    provider.resetVerification(df: true);
                  else
                    provider.resetVerification(lxns: true);
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            IconButton(
              icon: Icon(
                showToken ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () => onToggleShow(!showToken),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            if (hasContent)
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                onPressed: () {
                  controller.clear();
                  if (isDf)
                    provider.resetVerification(df: true);
                  else
                    provider.resetVerification(lxns: true);
                },
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              )
            else
              IconButton(
                icon: const Icon(
                  Icons.content_paste,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text?.isNotEmpty ?? false) {
                    provider.handlePaste(data!.text!, isDf: isDf);
                  }
                },
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(int index, String text) {
    final isSelected = widget.mode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onModeChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, widget.gradientColor],
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? widget.activeColor : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
