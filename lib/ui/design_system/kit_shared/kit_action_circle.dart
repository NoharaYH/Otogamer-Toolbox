import 'package:flutter/material.dart';
import 'kit_bounce_scaler.dart';

/// 统一圆形操作按钮（如设置、菜单开关等）
class KitActionCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Color backgroundColor;

  const KitActionCircle({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return KitBounceScaler(
      onTap: onTap,
      child: Container(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 6.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
