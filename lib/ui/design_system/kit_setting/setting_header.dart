import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../kit_shared/kit_bounce_scaler.dart';

/// 设置页顶部动态导航栏 (kit_setting 原子组件)
///
/// 统一处理两种状态：
/// - 根状态 (isSubPage: false)：纯文字"返回首页"行，无 Hero 无彩色圆形。
/// - 二级页状态 (isSubPage: true)：彩色圆形徽章（双图标叠加淡切换）+
///   Hero 标题，圆角/字号随 expansionProgress 插值。
class SettingHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onBack;

  /// 0.0 = 卡片态（圆角 20px，字号 17，分类图标）
  /// 1.0 = 完全扩张（无圆角，字号 20，返回图标）
  final double expansionProgress;

  /// true：渲染二级页带 Hero 的徽章样式标题行
  /// false：渲染一级根 Header（纯返回文字）
  final bool isSubPage;

  const SettingHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onBack,
    this.expansionProgress = 1.0,
    this.isSubPage = true,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    if (!isSubPage) {
      return _buildRootHeader(topPadding);
    }

    // 物理规程：圆角随扩张消失 (20.0 -> 0.0)
    final borderRadius = _lerp(20.0, 0.0, expansionProgress);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: UiColors.black.withValues(alpha: 0.1 * expansionProgress),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
        child: SizedBox(
          height: 54,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 彩色圆形徽章：双图标叠加淡入淡出切换
              KitBounceScaler(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 返回箭头（二级完全扩张后可见）
                      Opacity(
                        opacity: expansionProgress,
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      // 分类图标（卡片态可见）
                      Opacity(
                        opacity: 1 - expansionProgress,
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),

              // 标题：字号随进度从 17 缩放至 20，Hero 锚点
              Positioned(
                left: 48,
                child: Hero(
                  tag: 'category_title_$title',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: _lerp(17.0, 20.0, expansionProgress),
                        fontWeight: FontWeight.w900,
                        color: UiColors.grey800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 根 Header：纯白色矩形，返回箭头 + "返回首页"文字，无 Hero
  Widget _buildRootHeader(double topPadding) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: UiColors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPadding),
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.transparent,
              child: Row(
                children: [
                  KitBounceScaler(
                    onTap: onBack,
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '返回首页',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
