import 'package:flutter/material.dart';
import '../constants/animations.dart';

/// 统一动效缩放包装器 (v2.2)
/// 提取自 ConfirmButton，提供全局规范下的 "按下即时收缩，松开即时回正" 物理反馈。
/// 用于包装所有需要点击反馈的非标准化按钮 (如难标、操作圈等)。
class KitBounceScaler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;

  const KitBounceScaler({
    super.key,
    required this.child,
    this.onTap,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<KitBounceScaler> createState() => _KitBounceScalerState();
}

class _KitBounceScalerState extends State<KitBounceScaler>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // 收缩时极速响应，与 ConfirmButton 保持一致
      duration: UiAnimations.micro,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: UiAnimations.bounceScale)
        .animate(
          CurvedAnimation(parent: _controller, curve: UiAnimations.bounceCurve),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isInteractive => widget.onTap != null;

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
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onTap,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}
