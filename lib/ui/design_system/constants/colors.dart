import 'package:flutter/material.dart';

/// 纯粹中立的基准颜色表 (UI Colors)
/// 不属于任何皮肤特权，仅提供基础黑白灰的骨架定义
class UiColors {
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // 灰色阶梯 (由浅到深)
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF323232);
  static const Color grey900 = Color(0xFF212121);

  // 全局语义功能色
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFFF1744);

  // 统一交互面具色
  static const Color disabledMask = Color(0x99000000); // 60% 黑色遮罩
}
