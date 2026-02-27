import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../visual_skins/skin_extension.dart';
import '../constants/sizes.dart';
import '../constants/animations.dart';
import 'kit_bounce_scaler.dart';

/// 按钮状态枚举
enum ConfirmButtonState { ready, loading, disabled, hidden }

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
  final double? borderRadius;

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
    this.borderRadius,
  });

  @override
  State<ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<ConfirmButton> {
  // Loaded 状态优先级最高，直接阻塞交互
  bool get _isInteractive =>
      widget.state == ConfirmButtonState.ready && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final skin = Theme.of(context).extension<SkinExtension>();
    final baseColor = skin?.medium ?? UiColors.grey500;

    // 确定背景色
    Color buttonColor;
    bool showLoading = widget.state == ConfirmButtonState.loading;

    if (showLoading) {
      // 加载中：亮度严格降低 50%
      buttonColor = Color.lerp(baseColor, UiColors.black, 0.5)!;
      showLoading = true;
    } else {
      buttonColor = baseColor;
    }

    final bool isDisabled =
        widget.state == ConfirmButtonState.disabled || widget.onPressed == null;

    if (widget.state == ConfirmButtonState.hidden) {
      return const SizedBox.shrink();
    }

    return KitBounceScaler(
      onTap: _isInteractive ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: UiAnimations.fast,
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
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? UiSizes.buttonRadius,
          ),
          boxShadow: null,
        ),
        foregroundDecoration: isDisabled
            ? BoxDecoration(
                color: UiColors.disabledMask,
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? UiSizes.buttonRadius,
                ),
              )
            : null,
        child: Center(
          child: AnimatedSwitcher(
            duration: UiAnimations.fast,
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
                          color: UiColors.white,
                          size: widget.fontSize * 1.2,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: UiColors.white,
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
    );
  }
}
