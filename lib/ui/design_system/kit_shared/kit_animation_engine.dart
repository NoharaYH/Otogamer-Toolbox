import 'package:flutter/material.dart';

/// 统一动效展开引擎协议
class KitAnimationEngine {
  /// 全局标准：侧边栏、对话框等展开类组件的标准平滑阻尼曲线 (快-慢-快/缓出)
  static const Curve decelerateCurve = Curves.easeOutQuart;

  /// 全局标准：弹窗淡出的标准曲线 (快出)
  static const Curve accelerateCurve = Curves.easeIn;

  /// 展开/淡入/弹出类的基础持续时间 (600ms，提供拉丝感)
  static const Duration expandDuration = Duration(milliseconds: 600);

  /// 消失/收缩类的基础持续时间 (300ms，快速离开)
  static const Duration collapseDuration = Duration(milliseconds: 350);
}
