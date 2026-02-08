import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import 'transfer_page_maimaidx.dart';
import 'transfer_page_chunithm.dart';

class TransferModeCard extends StatefulWidget {
  final Color baseColor;
  final Color borderColor;
  final Color shadowColor;
  final Color containerColor;
  final Color activeColor;
  final Color gradientColor;
  final int mode; // 0: 水鱼, 1: 双平台, 2: 落雪
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
  // Token Management
  final TextEditingController _dfController = TextEditingController();
  final TextEditingController _lxnsController = TextEditingController();

  bool _showDfToken = false;
  bool _showLxnsToken = false;

  // Verification Status
  bool _isDivingFishVerified = false;
  bool _isLxnsVerified = false;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  @override
  void dispose() {
    _dfController.dispose();
    _lxnsController.dispose();
    super.dispose();
  }

  Future<void> _loadTokens() async {
    final df = await StorageService.read(StorageService.kDivingFishToken);
    final lxns = await StorageService.read(StorageService.kLxnsToken);
    if (mounted) {
      setState(() {
        if (df != null && df.isNotEmpty) {
          _dfController.text = df;
          // User requested: if token exists on launch, show success page immediately
          _isDivingFishVerified = true;
        }
        if (lxns != null && lxns.isNotEmpty) {
          _lxnsController.text = lxns;
          _isLxnsVerified = true;
        }
      });
    }
  }

  Future<void> _verifyAndSave() async {
    // 1. Check requirements based on Mode
    final needsDf = widget.mode == 0 || widget.mode == 1;
    final needsLxns = widget.mode == 2 || widget.mode == 1;

    // 2. Validate Inputs locally
    if (needsDf && _dfController.text.isEmpty) {
      _showError("请输入水鱼 Token");
      return;
    }
    if (needsLxns && _lxnsController.text.isEmpty) {
      _showError("请输入落雪 Token");
      return;
    }

    setState(() => _isValidating = true);

    bool dfSuccess = _isDivingFishVerified;
    bool lxnsSuccess = _isLxnsVerified;
    String? errorMsg;

    try {
      // 3. Remote Verification (Parallel if needed, but sequential is safer for error handling)

      // Verify Diving Fish if needed and not already verified
      if (needsDf && !dfSuccess) {
        final dfValid = await ApiService.validateDivingFishToken(
          _dfController.text,
        );
        if (dfValid) {
          dfSuccess = true;
        } else {
          errorMsg = "水鱼 Token 验证失败，请检查是否正确";
        }
      }

      // Verify LXNS if needed and not already verified (and if DF passed or not processing DF)
      if (needsLxns && !lxnsSuccess && errorMsg == null) {
        final lxnsValid = await ApiService.validateLxnsToken(
          _lxnsController.text,
        );
        if (lxnsValid) {
          lxnsSuccess = true;
        } else {
          errorMsg = "落雪 Token 验证失败，请检查是否正确";
        }
      }
    } catch (e) {
      errorMsg = "网络请求异常: $e";
    }

    if (!mounted) return;

    setState(() {
      _isValidating = false;
      if (errorMsg != null) {
        // Validation Failed
        _showError(errorMsg);
      } else {
        // Validation Success
        _isDivingFishVerified = dfSuccess;
        _isLxnsVerified = lxnsSuccess;

        // Save Tokens
        if (dfSuccess)
          StorageService.save(
            StorageService.kDivingFishToken,
            _dfController.text,
          );
        if (lxnsSuccess)
          StorageService.save(StorageService.kLxnsToken, _lxnsController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('验证通过，配置已保存'),
            backgroundColor: widget.activeColor,
            duration: const Duration(seconds: 1),
          ),
        );
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _handlePaste(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      if (!mounted) return;
      final shouldPaste = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('检测到剪贴板内容'),
          content: Text(
            '是否粘贴以下内容？\n\n"${data.text!.length > 20 ? "${data.text!.substring(0, 20)}..." : data.text}"',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('粘贴'),
            ),
          ],
        ),
      );

      if (shouldPaste == true) {
        controller.text = data.text!;
        // Reset verification status on modification
        if (controller == _dfController) _isDivingFishVerified = false;
        if (controller == _lxnsController) _isLxnsVerified = false;
        setState(() {});
      }
    }
  }

  Widget _buildTokenField({
    required TextEditingController controller,
    required String hint,
    required bool showToken,
    required ValueChanged<bool> onToggleShow,
    required VoidCallback onResetVerify,
  }) {
    final hasContent = controller.text.isNotEmpty;
    final bgColor = hasContent ? Colors.grey[100] : Colors.grey[300];

    return GestureDetector(
      onTap: () {
        if (!hasContent) _handlePaste(controller);
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
                  onResetVerify();
                  setState(() {});
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
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            if (hasContent)
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                onPressed: () {
                  controller.clear();
                  onResetVerify();
                  setState(() {});
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              )
            else
              IconButton(
                icon: const Icon(
                  Icons.content_paste,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () => _handlePaste(controller),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(
    int index,
    String text,
    int currentMode,
    ValueChanged<int> onSelected,
    Color activeColor,
    Color gradientColor,
  ) {
    final isSelected = currentMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(index),
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
                    colors: [Colors.white, gradientColor],
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
              color: isSelected ? activeColor : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic to determine readiness
    final needsDf = widget.mode == 0 || widget.mode == 1;
    final needsLxns = widget.mode == 2 || widget.mode == 1;

    // Check if tokens are present and "verified" (or loaded)
    // For Double Mode (1), BOTH must be ready to show success page.
    final bool isDfReady =
        !needsDf || (_isDivingFishVerified && _dfController.text.isNotEmpty);
    final bool isLxnsReady =
        !needsLxns || (_isLxnsVerified && _lxnsController.text.isNotEmpty);

    final bool showSuccessPage = isDfReady && isLxnsReady;

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
          // Buttons Row (Always Visible)
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
                _buildModeTab(
                  0,
                  '水鱼',
                  widget.mode,
                  widget.onModeChanged,
                  widget.activeColor,
                  widget.gradientColor,
                ),
                _buildModeTab(
                  1,
                  '双平台',
                  widget.mode,
                  widget.onModeChanged,
                  widget.activeColor,
                  widget.gradientColor,
                ),
                _buildModeTab(
                  2,
                  '落雪',
                  widget.mode,
                  widget.onModeChanged,
                  widget.activeColor,
                  widget.gradientColor,
                ),
              ],
            ),
          ),

          // Content Area (Switches between Input and Success Page)
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
                switchInCurve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                child: showSuccessPage
                    ? Column(
                        key: ValueKey<String>('Success_${widget.gameType}'),
                        children: [
                          // Header Row for Success Page
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
                                      setState(() {
                                        _isDivingFishVerified = false;
                                        _isLxnsVerified = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: widget.activeColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                    ),
                                    child: const Text(
                                      "返回token填写",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                      )
                    : Column(
                        key: ValueKey<int>(widget.mode),
                        children: [
                          const SizedBox(height: 8),
                          if (needsDf)
                            _buildTokenField(
                              controller: _dfController,
                              hint: '请输入水鱼成绩导入Token',
                              showToken: _showDfToken,
                              onToggleShow: (v) =>
                                  setState(() => _showDfToken = v),
                              onResetVerify: () =>
                                  _isDivingFishVerified = false,
                            ),
                          if (needsLxns)
                            _buildTokenField(
                              controller: _lxnsController,
                              hint: '请输入落雪个人API密钥',
                              showToken: _showLxnsToken,
                              onToggleShow: (v) =>
                                  setState(() => _showLxnsToken = v),
                              onResetVerify: () => _isLxnsVerified = false,
                            ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _isValidating ? null : _verifyAndSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.activeColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isValidating
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
