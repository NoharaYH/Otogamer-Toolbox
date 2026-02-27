import 'package:flutter/material.dart';
import '../visual_skins/skin_extension.dart';
import '../constants/animations.dart';

class KitNavCapsule extends StatefulWidget {
  final IconData icon;
  final String? label;
  final String? subLabel;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isCircle;

  const KitNavCapsule({
    required this.icon,
    this.label,
    this.subLabel,
    required this.onTap,
    this.isSelected = false,
    this.isCircle = false,
    super.key,
  });

  @override
  State<KitNavCapsule> createState() => _KitNavCapsuleState();
}

class _KitNavCapsuleState extends State<KitNavCapsule> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    // 由于 NavDeckOverlay 在 RootPage 层，其 context 可能尚未被 KitGameCarousel 注入 SkinExtension
    // 所以我们需要做安全的 null 处理，并提供 fallback 颜色
    final skin = Theme.of(context).extension<SkinExtension>();

    final bgColor = Colors.white;

    // Define colors, providing fallbacks if skin is not available
    final Color mediumColor = skin?.medium ?? Colors.blueAccent;
    final Color darkColor = skin?.dark ?? Colors.black87;

    final contentColor = widget.isSelected
        ? mediumColor
        : mediumColor.withValues(alpha: 0.6);

    // 强制内部元素跟随组件设定的 55.2 高宽 (46 * 1.2)
    const double capSize = 55.2;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: AnimatedContainer(
          duration: UiAnimations.fast,
          curve: Curves.easeOutCubic,
          height: capSize,
          width: widget.isCircle ? capSize : null,
          padding: widget.isCircle
              ? EdgeInsets.zero
              /// 修改为左右不对等的大垫充，以此自然拉开卡片横向距离取代之前致错的强制写死屏宽Width
              : const EdgeInsets.only(
                  left: 8.4,
                  top: 8.4,
                  bottom: 8.4,
                  right: 36.0,
                ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(capSize / 2),
            // 物理投影
            boxShadow: [
              BoxShadow(
                color: darkColor.withValues(alpha: 0.15),
                blurRadius: 16.0,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              if (widget.isSelected)
                BoxShadow(
                  color: mediumColor.withValues(alpha: 0.2),
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          alignment: widget.isCircle ? Alignment.center : Alignment.centerLeft,
          child: widget.isCircle
              // 独立的圆形按钮: 主题色 Icon，无需底色
              ? Icon(
                  widget.icon,
                  color: widget.isSelected ? darkColor : mediumColor,
                  size: 28.8,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 左端 Icon (圆形 + 主题色底，38.4x38.4)
                    Container(
                      width: 38.4,
                      height: 38.4,
                      decoration: BoxDecoration(
                        color: mediumColor, // 完美中心圆的主题底色
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(widget.icon, color: Colors.white, size: 21.6),
                    ),
                    if (widget.label != null) ...[
                      const SizedBox(width: 9.6), // 文字距 Icon 的间隙
                      // 双行文字
                      SizedBox(
                        // 高度锁定为38.4，让 Column 刚好与 Icon 上下顶对齐
                        height: 38.4,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.subLabel != null)
                              Text(
                                widget.subLabel!,
                                style: TextStyle(
                                  fontFamily: 'JiangCheng',
                                  color: contentColor,
                                  fontSize: 13.2,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                ),
                              ),
                            Text(
                              widget.label!,
                              style: TextStyle(
                                fontFamily: 'JiangCheng',
                                color: contentColor,
                                fontSize: 19.2, // 大号标题
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
