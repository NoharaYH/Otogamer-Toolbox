import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../kit_shared/kit_bounce_scaler.dart';

/// 设置页一级菜单行项目 (kit_setting 原子组件)
///
/// 圆角纯白阴影行容器，左侧彩色实心圆背景图标徽章，
/// 中部加粗标题文字，标题挂载 Hero 锚点，整体包裹弹性缩放点按动效。
class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback onTap;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KitBounceScaler(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: UiColors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 彩色实心圆背景图标徽章
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            // Hero 标题
            Hero(
              tag: 'category_title_$title',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
