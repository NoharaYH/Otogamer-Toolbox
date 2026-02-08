import 'package:flutter/material.dart';

class ChunithmView extends StatelessWidget {
  const ChunithmView({super.key});

  @override
  Widget build(BuildContext context) {
    // 基础设计尺寸，来自 Figma
    const double designWidth = 393.0;
    const double designHeight = 852.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算缩放比例，使得宽度充满屏幕
        final double scale = constraints.maxWidth / designWidth;

        // 使用 Stack + Positioned 还原 Figma 的绝对定位布局
        // 注意：这里使用 OverflowBox 允许组件超出屏幕范围
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight, // 使用高度填充
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. 背景层 (Background Layer)
              // HTML: width: 1514px; height: 852px; left: -592px; top: 0px
              Positioned(
                left: -592 * scale, // 根据屏幕缩放调整偏移
                top: 0,
                width: 1514 * scale,
                height: 852 * scale, // 高度也随比例缩放，保持纵横比
                child: Image.asset(
                  'assets/background/chunithm/bg.jpg.webp',
                  fit: BoxFit.cover,
                ),
              ),

              // 2. 城镇层 (Town Layer)
              // HTML: width: 1500px; height: 733px; left: -515px; top: 119px
              Positioned(
                left: -515 * scale,
                top: 119 * scale,
                width: 1500 * scale,
                height: 733 * scale,
                child: Image.asset(
                  'assets/background/chunithm/verse-town.png.webp',
                  fit: BoxFit.cover,
                ),
              ),

              // 3. 顶部 Logo (Top Logo)
              // HTML: width: 345px; height: 72px; left: 48px; top: 0px (implied)
              // 注意：Figma HTML 里有一个类似的 img，这里使用了 provided 的 logo
              Positioned(
                left: 48 * scale,
                top: MediaQuery.of(context).padding.top + 10, // 适配刘海屏
                width: 345 * scale,
                height: 72 * scale,
                child: Image.asset(
                  'assets/logo/top_main_logo.webp',
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),
              ),

              // 底部渐变遮罩 (模拟 HTML 中的 radial-gradient)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        const Color(0xFFFFB7CD).withOpacity(0.0), // 透明中心
                        const Color(0xFFFF59A1).withOpacity(0.1), // 边缘淡淡粉色
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
