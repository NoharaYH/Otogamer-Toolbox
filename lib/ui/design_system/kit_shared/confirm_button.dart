import 'package:flutter/material.dart';
import '../visual_skins/skin_extension.dart';
import '../constants/sizes.dart';

/// 按钮状态枚举
enum ConfirmButtonState {
  ready, // 普通 / 可点击
  loading, // 加载中（最高优先级：强制阻塞点击 + 变暗 + 圈圈）
}

/// 统一动效按钮 (v2.2 - 简化状态版)
class ConfirmButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ConfirmButtonState state;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double fontSize;

  const ConfirmButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.state = ConfirmButtonState.ready,
    this.width,
    this.height,
    this.padding,
    this.fontSize = 14,
  });

  @override
  State<ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<ConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Loaded 状态优先级最高，直接阻塞交互
  bool get _isInteractive =>
      widget.state != ConfirmButtonState.loading && widget.onPressed != null;

  void _onPointerDown(PointerDownEvent event) {
    if (_isInteractive) {
      _controller.forward();
    }
  }

  void _onPointerUp(PointerEvent event) {
    if (_isInteractive) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = Theme.of(context).extension<SkinExtension>();
    final baseColor = skin?.medium ?? Colors.pink;

    // 确定背景色
    Color buttonColor;
    bool showLoading = widget.state == ConfirmButtonState.loading;

    if (showLoading) {
      // 加载中：亮度严格降低 50%
      buttonColor = Color.lerp(baseColor, Colors.black, 0.5)!;
      showLoading = true;
    } else if (widget.onPressed == null) {
      // 禁用：灰色 (Disabled 状态移除，由 onPressed 是否为空决定)
      buttonColor = Colors.grey.withOpacity(0.4);
    } else {
      buttonColor = baseColor;
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isInteractive ? widget.onPressed : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.width,
            height:
                widget.height ??
                (widget.padding == null ? UiSizes.inputFieldHeight : null),
            padding:
                widget.padding ??
                (widget.height == null
                    ? const EdgeInsets.symmetric(horizontal: 16)
                    : null),
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(UiSizes.buttonBorderRadius),
              boxShadow: null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: showLoading
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: widget.fontSize * 1.5,
                        height: widget.fontSize * 1.5,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3, // 稍微加粗，更醒目
                        ),
                      )
                    : Row(
                        key: const ValueKey('content'),
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: Colors.white,
                              size: widget.fontSize * 1.2,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: widget.fontSize,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
