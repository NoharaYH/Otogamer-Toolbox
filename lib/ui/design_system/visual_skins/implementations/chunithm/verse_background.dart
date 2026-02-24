import 'package:flutter/material.dart';
import '../../skin_extension.dart';
import '../../../constants/assets.dart';

/// 中二节奏 - Verse Town 主题皮肤
class ChunithmSkin extends SkinExtension {
  const ChunithmSkin();

  // ==================== 主题色定义 ====================

  @override
  Color get light => const Color.fromARGB(255, 165, 208, 255); // 浅蓝 - 渐变起始

  @override
  Color get medium => const Color.fromARGB(255, 111, 140, 255); // 金黄 - 按钮/激活态

  @override
  Color get dark => const Color.fromARGB(255, 0, 98, 255); // 深蓝 - 边框/阴影

  // ==================== 背景渲染 ====================

  @override
  Widget buildBackground(BuildContext context) {
    const double designWidth = 393.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = constraints.maxWidth / designWidth;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(AppAssets.chunithmBg, fit: BoxFit.cover),
            ),
            Positioned(
              left: -515 * scale,
              bottom: 0,
              width: 1500 * scale,
              height: 733 * scale,
              child: Image.asset(
                AppAssets.chunithmVerseTown,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                AppAssets.chunithmTopRight,
                width: constraints.maxWidth * 1.7,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Image.asset(
                AppAssets.chunithmBottomLeft,
                width: constraints.maxWidth * 1.7,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }

  // ==================== ThemeExtension 必需方法 ====================

  @override
  SkinExtension copyWith({Color? light, Color? medium, Color? dark}) {
    return this;
  }
}
