import 'package:flutter/material.dart';
import '../theme/core/app_theme.dart';

/// 游戏轮播项元数据
/// 用于描述参与轮播的每一个游戏页面的皮肤、内容和基础信息
class GamePageItem {
  /// 该页面对应的视觉皮肤实现
  final AppTheme skin;

  /// 该页面的具体业务组件内容
  final Widget content;

  /// 分页标识名称（用于调试或埋点）
  final String title;

  const GamePageItem({
    required this.skin,
    required this.content,
    required this.title,
  });
}
