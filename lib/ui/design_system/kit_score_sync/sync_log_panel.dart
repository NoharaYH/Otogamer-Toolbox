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
  final String logs;
  final VoidCallback onCopy;
  final VoidCallback onClose;
  final bool forceHidden;

  const SyncLogPanel({
    super.key,
    required this.logs,
    required this.onCopy,
    required this.onClose,
    this.forceHidden = false,
  });

  @override
  State<SyncLogPanel> createState() => _SyncLogPanelState();
}

class _SyncLogPanelState extends State<SyncLogPanel> {
  bool isShown = false; // 是否显示胶囊外壳
  bool isActuallyExpanded = false; // 是否扩张内部正文

  // 内部滚动控制器
  late final ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();

    if (!widget.forceHidden && widget.logs.isNotEmpty) {
      isShown = true;
      isActuallyExpanded = true;
    } else if (!widget.forceHidden) {
      startEntryAnimation();
    }
  }

  @override
  void didUpdateWidget(SyncLogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.forceHidden && !widget.forceHidden) {
      startEntryAnimation();
    }

    if (widget.forceHidden && isShown) {
      setState(() => isActuallyExpanded = false);
      Future.delayed(KitAnimationEngine.expandDuration, () {
        if (mounted) setState(() => isShown = false);
      });
    }

    if (widget.logs != oldWidget.logs && isActuallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void startEntryAnimation() {
    setState(() => isShown = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !widget.forceHidden) {
        setState(() => isActuallyExpanded = true);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 规程：间距内化，防止关闭时残留边距
    final double targetHeight = isActuallyExpanded
        ? UiSizes.getLogPanelMaxHeight(context, UiSizes.syncFormEstimatedHeight)
        : (isShown ? 38.0 : 0.0);

    // 规程：间距作为高度的一部分
    final double totalHeight = isShown ? targetHeight + UiSizes.spaceS : 0.0;

    return AnimatedOpacity(
      duration: KitAnimationEngine.shortDuration,
      opacity: isShown ? 1.0 : 0.0,
      child: AnimatedScale(
        duration: KitAnimationEngine.shortDuration,
        scale: isShown ? 1.0 : 0.95,
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: KitAnimationEngine.expandDuration,
          curve: KitAnimationEngine.decelerateCurve,
          width: double.infinity,
          height: totalHeight,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: UiSizes.spaceS),
                AnimatedContainer(
                  duration: KitAnimationEngine.expandDuration,
                  curve: KitAnimationEngine.decelerateCurve,
                  height: targetHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF323232),
                    borderRadius: BorderRadius.circular(
                      UiSizes.buttonBorderRadius,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildLogContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogContent() {
    return Column(
      children: [
        // 工具栏
        SizedBox(
          height: 38,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconButton(icon: Icons.content_copy, onTap: widget.onCopy),
              _IconButton(icon: Icons.close, onTap: widget.onClose),
            ],
          ),
        ),

        // 内容区域
        Expanded(
          child: AnimatedOpacity(
            duration: KitAnimationEngine.shortDuration,
            opacity: isActuallyExpanded ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: RawScrollbar(
                controller: scrollController,
                thumbColor: Colors.white.withValues(alpha: 0.3),
                radius: const Radius.circular(3),
                thickness: 3,
                interactive: true,
                child: SelectionArea(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.topLeft,
                      child: Text(
                        widget.logs.isEmpty ? "等待日志输入..." : widget.logs,
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
            ),
          ),
        ),
      ],
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
