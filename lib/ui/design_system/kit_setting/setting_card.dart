import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../kit_shared/kit_staggered_entrance.dart';

/// 设置页通用圆角阴影卡片容器 (kit_setting 原子组件)
/// 遵循 CARD_PROTOCOL：固定圆角、阴影、图标+标题头部，内容为插槽。
class SettingCard extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final Widget child;

  const SettingCard({
    super.key,
    required this.index,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return KitStaggeredEntrance(
      index: index,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(UiSizes.cardContentPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(UiSizes.cardRadius),
          boxShadow: [
            BoxShadow(
              color: UiColors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: UiColors.grey700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: UiColors.grey800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
