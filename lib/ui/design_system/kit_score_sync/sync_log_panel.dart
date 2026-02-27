import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/sizes.dart';
import '../constants/animations.dart';
import '../constants/strings.dart';
import '../kit_shared/kit_animation_engine.dart';
import '../kit_shared/kit_bounce_scaler.dart';

/// 同步状态日志面板
///
/// 行为描述：
/// - 常驻胶囊基态：一经挂载即以胶囊形式常驻（isShown 永久为 true）
/// - 传分启动后展开至目标高度，物理扩张完成后以 50ms 间隔逐行输出日志文字
/// - 按钮状态分层：胶囊态灰色禁用；展开态白色可交互，附带圆形半透明底纹
/// - 几何约束：日志框圆角拉升至胶囊极值（半高），底纹圆圈与边角等圆心对齐
class SyncLogPanel extends StatefulWidget {
  final String logs;
  final VoidCallback onCopy;
  final VoidCallback onClose;
  final VoidCallback onConfirmPause;
  final VoidCallback onConfirmResume;
  final bool isTracking;

  const SyncLogPanel({
    super.key,
    required this.logs,
    required this.onCopy,
    required this.onClose,
    required this.onConfirmPause,
    required this.onConfirmResume,
    this.isTracking = false,
  });

  @override
  State<SyncLogPanel> createState() => _SyncLogPanelState();
}

class _SyncLogPanelState extends State<SyncLogPanel>
    with SingleTickerProviderStateMixin {
  // 展开状态
  bool _isExpanded = false;

  // 逐行日志渲染状态
  List<String> _pendingLines = [];
  List<String> _displayedLines = [];
  Timer? _lineTimer;

  // 确认框 layout 存在状态
  bool _isConfirmInLayout = false;
  VoidCallback? _pendingCallback;

  late final ScrollController _scrollController;
  late final AnimationController _confirmController;
  late final Animation<double> _confirmFade;
  late final Animation<Offset> _confirmSlide;

  // 工具栏固定高度
  static const double _toolbarHeight = 38.0;
  // 胶囊底纹圆圈的外径（等于工具栏高度 → 贴边同圆心）
  static const double _buttonCircleSize = _toolbarHeight;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _confirmController = AnimationController(
      vsync: this,
      duration: KitAnimationEngine.shortDuration,
      reverseDuration: KitAnimationEngine.shortDuration,
    );

    _confirmFade = CurvedAnimation(
      parent: _confirmController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _confirmSlide =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _confirmController,
            curve: KitAnimationEngine.decelerateCurve,
            reverseCurve: KitAnimationEngine.accelerateCurve,
          ),
        );

    _confirmController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() => _isConfirmInLayout = false);
        _pendingCallback?.call();
        _pendingCallback = null;
      }
    });
    // 状态保持逻辑: 若正在追踪，或者已经有日志内容（代表已完成但未关闭），保持展开
    if (widget.isTracking || widget.logs.isNotEmpty) {
      _isExpanded = true;
    }

    // 初始化时对已存在的 logs 执行首次同步展示，防止面板在切回时为空
    if (widget.logs.isNotEmpty) {
      final List<String> incoming = widget.logs.split('\n');
      if (incoming.isNotEmpty && incoming.last.isEmpty) {
        incoming.removeLast();
      }
      _displayedLines = incoming;

      // 首帧滚动到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void didUpdateWidget(SyncLogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 传分启动：触发展开（文字由下方水坝分支并行流出，无需延迟）
    if (!oldWidget.isTracking && widget.isTracking) {
      setState(() {
        _isExpanded = true;
        _displayedLines = [];
        _pendingLines = [];
      });
    }

    // 传分结束：不再自动收缩，实现“传分完成后驻留”
    if (oldWidget.isTracking && !widget.isTracking) {
      _stopLineFlush();
      _forceResetConfirm();
      // setState(() => _isExpanded = false); // REMOVED
    }

    // 新日志入水坝 (移除 isTracking 限制，并修复 split('\n') 结尾空行的偏移 Bug)
    if (widget.logs != oldWidget.logs) {
      final List<String> incoming = widget.logs.split('\n');
      // 处理 .split('\n') 带来的末尾空字符串问题，保持与实发行数一致
      if (incoming.isNotEmpty && incoming.last.isEmpty) {
        incoming.removeLast();
      }

      final int currentTotal = _displayedLines.length + _pendingLines.length;

      if (incoming.length > currentTotal) {
        final newLines = incoming.sublist(currentTotal);
        if (newLines.isNotEmpty) {
          _pendingLines.addAll(newLines);
          _lineTimer ??= Timer.periodic(
            const Duration(milliseconds: 50),
            _drainOneLine,
          );
        }
      }
    }
  }

  void _drainOneLine(Timer t) {
    if (!mounted) {
      t.cancel();
      _lineTimer = null;
      return;
    }
    if (_pendingLines.isEmpty) {
      // 队列清空，但保留 timer 等待新到的行
      return;
    }
    setState(() {
      _displayedLines.add(_pendingLines.removeAt(0));
    });
    // 滚动至底
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _stopLineFlush() {
    _lineTimer?.cancel();
    _lineTimer = null;
  }

  // 关闭意图
  void _triggerCloseIntent() {
    if (!widget.isTracking) {
      // 传分已结束，点击关闭直接收缩面板并执行清理逻辑
      setState(() => _isExpanded = false);
      widget.onClose();
      return;
    }
    widget.onConfirmPause();
    _confirmController.reset();
    setState(() => _isConfirmInLayout = true);
    _confirmController.forward();
  }

  void _resolveConfirm({required bool confirmed}) {
    _pendingCallback = confirmed ? widget.onClose : widget.onConfirmResume;
    _confirmController.reverse();
  }

  void _forceResetConfirm() {
    _confirmController.stop();
    _confirmController.reset();
    _pendingCallback = null;
    if (mounted) setState(() => _isConfirmInLayout = false);
  }

  @override
  void dispose() {
    _stopLineFlush();
    _scrollController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 胶囊态高度 = 工具栏高 + 上边距
    // 展开态高度 = 计算目标高度
    final double targetHeight = _isExpanded
        ? UiSizes.getLogPanelMaxHeight(context, 464.0) // 临时硬编码预估高度，后续可进一步优化
        : _toolbarHeight;

    final double totalHeight = targetHeight;

    // 圆角规格与导入按钮统一 (v2.3)
    final double radius = UiSizes.buttonRadius;

    return AnimatedContainer(
      duration: KitAnimationEngine.expandDuration,
      curve: KitAnimationEngine.decelerateCurve,
      width: double.infinity,
      height: totalHeight,
      margin: const EdgeInsets.only(top: UiSizes.spaceS),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        children: [
          AnimatedContainer(
            duration: KitAnimationEngine.expandDuration,
            curve: KitAnimationEngine.decelerateCurve,
            height: targetHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF323232),
              borderRadius: BorderRadius.circular(UiSizes.buttonRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildLogContent(radius),
          ),
        ],
      ),
    );
  }

  Widget _buildLogContent(double radius) {
    return Column(
      children: [
        // 工具栏
        SizedBox(
          height: _toolbarHeight,
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // 复制按钮（左侧，边角吻合圆心）
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _LogIconButton(
                  icon: Icons.content_copy,
                  iconSize: 14,
                  isActive: _isExpanded,
                  circleSize: _buttonCircleSize,
                  outerRadius: radius,
                  onTap: _isExpanded ? widget.onCopy : null,
                ),
              ),
              // 关闭按钮（右侧，边角吻合圆心）
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _LogIconButton(
                  icon: _isConfirmInLayout ? Icons.more_horiz : Icons.close,
                  iconSize: 16,
                  isActive: _isExpanded,
                  circleSize: _buttonCircleSize,
                  outerRadius: radius,
                  onTap: (_isExpanded && !_isConfirmInLayout)
                      ? _triggerCloseIntent
                      : null,
                ),
              ),
              // 确认框
              if (_isConfirmInLayout)
                Positioned(
                  right: _buttonCircleSize,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: SlideTransition(
                      position: _confirmSlide,
                      child: FadeTransition(
                        opacity: _confirmFade,
                        child: Container(
                          height: 26,
                          padding: const EdgeInsets.symmetric(
                            horizontal: UiSizes.spaceXS,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              UiSizes.buttonRadius,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                UiStrings.confirmEndTransfer,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(width: UiSizes.spaceS),
                              _ConfirmIcon(
                                icon: Icons.check,
                                color: Colors.green,
                                size: 20,
                                onTap: () => _resolveConfirm(confirmed: true),
                              ),
                              const SizedBox(width: UiSizes.spaceXS),
                              _ConfirmIcon(
                                icon: Icons.close,
                                color: Colors.red,
                                size: 20,
                                onTap: () => _resolveConfirm(confirmed: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 日志内容区域，展开后淡入
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: UiAnimations.fast,
            style: const TextStyle(
              color: Color(0xFFEEEEEE),
              fontSize: 13,
              fontFamily: 'monospace',
              height: 1.4,
            ),
            child: AnimatedOpacity(
              duration: KitAnimationEngine.shortDuration,
              opacity: _isExpanded ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: RawScrollbar(
                  controller: _scrollController,
                  thumbColor: Colors.white.withOpacity(0.3),
                  radius: const Radius.circular(3),
                  thickness: 3,
                  interactive: true,
                  child: SelectionArea(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.topLeft,
                        child: Text(
                          _displayedLines.isEmpty
                              ? UiStrings.waitingLogs
                              : _displayedLines.join('\n'),
                          // Style is now handled by AnimatedDefaultTextStyle
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

/// 工具栏图标按钮
/// - 激活态：白色图标 + 半透明白色圆形底纹，与日志框边角等圆心对齐
/// - 禁用态：灰暗图标无底纹
class _LogIconButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final bool isActive;
  final double circleSize;
  final double outerRadius;
  final VoidCallback? onTap;

  const _LogIconButton({
    required this.icon,
    required this.iconSize,
    required this.isActive,
    required this.circleSize,
    required this.outerRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KitBounceScaler(
      onTap: onTap,
      child: SizedBox(
        width: circleSize,
        height: circleSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 同心圆角背景：Radius = 外部圆角 - 间距 (4.0)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isActive ? 1.0 : 0.0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(
                    UiSizes.buttonRadius - 4.0,
                  ),
                ),
              ),
            ),
            // 图标
            Icon(
              icon,
              size: iconSize,
              color: isActive ? Colors.white : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ConfirmIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return KitBounceScaler(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: size * 0.6),
      ),
    );
  }
}
