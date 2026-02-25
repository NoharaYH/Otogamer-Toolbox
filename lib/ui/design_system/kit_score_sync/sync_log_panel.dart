import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/sizes.dart';
import '../kit_shared/kit_animation_engine.dart';

/// 同步状态日志面板
///
/// 具有两段式动画：
/// 1. 胶囊：仅显示工具栏按钮
/// 2. 展开：显示日志内容并向下延伸
class SyncLogPanel extends StatefulWidget {
  final bool isExpanded;
  final String logs;
  final VoidCallback onCopy;
  final VoidCallback onClose;
  final bool forceHidden;

  const SyncLogPanel({
    super.key,
    required this.isExpanded,
    required this.logs,
    required this.onCopy,
    required this.onClose,
    this.forceHidden = false,
  });

  @override
  State<SyncLogPanel> createState() => _SyncLogPanelState();
}

class _SyncLogPanelState extends State<SyncLogPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _isShown = false; // 是否已浮现 (从0开始)
  bool _isActuallyExpanded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.forceHidden) {
      _startEntryAnimation();
    }
  }

  @override
  void didUpdateWidget(SyncLogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.forceHidden && !widget.forceHidden) {
      _startEntryAnimation();
    }

    if (widget.forceHidden) {
      _isShown = false;
      _isActuallyExpanded = false;
    }

    if (widget.isExpanded && !oldWidget.isExpanded) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _isActuallyExpanded = true);
      });
    } else if (!widget.isExpanded && oldWidget.isExpanded) {
      setState(() => _isActuallyExpanded = false);
    }

    // 当日志更新且处于展开状态时，自动滚动到底部
    if (widget.logs != oldWidget.logs && _isActuallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _startEntryAnimation() {
    // 阶段化时序：
    // 1. 等待白色卡片先行扩张 (600ms+)
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && !widget.forceHidden) {
        setState(() => _isShown = true);

        // 2. 胶囊浮现后，向下生长出内容
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !widget.forceHidden) {
            setState(() => _isActuallyExpanded = true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 【圆角对齐】直接锁定到“开始导入”按钮的圆角，不再动态变化
    const double borderRadius = UiSizes.buttonBorderRadius;

    return AnimatedSize(
      duration: KitAnimationEngine.expandDuration,
      curve: KitAnimationEngine.decelerateCurve, // 平滑曲线，防止抖动
      child: !_isShown
          ? const SizedBox(width: double.infinity, height: 0)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                UiSizes.atomicComponentGap,
                0,
                0,
              ),
              child: AnimatedContainer(
                duration: KitAnimationEngine.expandDuration,
                curve: KitAnimationEngine.decelerateCurve,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF323232),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部工具栏 (精准对齐圆角中心)
                    SizedBox(
                      height: 38, // 稍微收窄高度
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _IconButton(
                            icon: Icons.content_copy,
                            onTap: widget.onCopy,
                          ),
                          _IconButton(icon: Icons.close, onTap: widget.onClose),
                        ],
                      ),
                    ),

                    // 日志内容区
                    AnimatedSize(
                      duration: KitAnimationEngine.expandDuration,
                      curve: KitAnimationEngine.decelerateCurve,
                      child: _isActuallyExpanded
                          ? ConstrainedBox(
                              // 【回归标准】高度恢复到 280，适配新的大框间距
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: SelectionArea(
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        widget.logs.isEmpty
                                            ? "等待日志输入..."
                                            : widget.logs,
                                        style: const TextStyle(
                                          color: Color(0xFFEEEEEE),
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox(width: double.infinity, height: 0),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiSizes.buttonBorderRadius),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white54, size: 18),
        ),
      ),
    );
  }
}
