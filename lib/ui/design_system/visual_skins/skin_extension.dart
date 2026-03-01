import 'package:flutter/material.dart';

/// 皮肤扩展接口
/// 每个具体的皮肤实现此接口，提供主题色和渲染逻辑
abstract class SkinExtension extends ThemeExtension<SkinExtension> {
  const SkinExtension();

  /// 亮色调 - 用于背景渐变、玻璃效果叠加层
  Color get light;

  /// 中性色调 - 用于主要 UI 元素（卡片、按钮激活态）
  Color get medium;

  /// 暗色调 - 用于边框、阴影、分割线
  Color get dark;

  /// 副标题颜色 - 特别用于 Logo 下方的文字
  Color get subtitleColor;

  /// 页面指示点颜色
  Color get dotColor;

  /// 渲染背景 Widget
  Widget buildBackground(BuildContext context);

  @override
  SkinExtension copyWith({
    Color? light,
    Color? medium,
    Color? dark,
    Color? subtitleColor,
    Color? dotColor,
  });

  @override
  SkinExtension lerp(ThemeExtension<SkinExtension>? other, double t) {
    if (other is! SkinExtension) return this;
    return ThemeSkin(
      lightColor: Color.lerp(light, other.light, t) ?? light,
      mediumColor: Color.lerp(medium, other.medium, t) ?? medium,
      darkColor: Color.lerp(dark, other.dark, t) ?? dark,
      subtitleColor_:
          Color.lerp(subtitleColor, other.subtitleColor, t) ?? subtitleColor,
      dotColor_: Color.lerp(dotColor, other.dotColor, t) ?? dotColor,
      baseSkin: t < 0.5 ? this : other,
    );
  }
}

/// 用于插值的临时皮肤实现
class ThemeSkin extends SkinExtension {
  final Color lightColor;
  final Color mediumColor;
  final Color darkColor;
  final Color subtitleColor_;
  final Color dotColor_;
  final SkinExtension baseSkin;

  const ThemeSkin({
    required this.lightColor,
    required this.mediumColor,
    required this.darkColor,
    required this.subtitleColor_,
    required this.dotColor_,
    required this.baseSkin,
  });

  @override
  Color get light => lightColor;
  @override
  Color get medium => mediumColor;
  @override
  Color get dark => darkColor;
  @override
  Color get subtitleColor => subtitleColor_;
  @override
  Color get dotColor => dotColor_;

  @override
  Widget buildBackground(BuildContext context) =>
      baseSkin.buildBackground(context);

  @override
  SkinExtension copyWith({
    Color? light,
    Color? medium,
    Color? dark,
    Color? subtitleColor,
    Color? dotColor,
  }) {
    return ThemeSkin(
      lightColor: light ?? lightColor,
      mediumColor: medium ?? mediumColor,
      darkColor: dark ?? darkColor,
      subtitleColor_: subtitleColor ?? subtitleColor_,
      dotColor_: dotColor ?? dotColor_,
      baseSkin: baseSkin,
    );
  }
}
