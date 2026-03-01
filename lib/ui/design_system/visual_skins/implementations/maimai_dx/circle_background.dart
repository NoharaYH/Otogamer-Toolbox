import 'package:flutter/material.dart';
import '../../skin_extension.dart';
import '../../../constants/assets.dart';

/// 舞萌 DX - Circle 主题皮肤
class MaimaiSkin extends SkinExtension {
  const MaimaiSkin();

  // ==================== 主题色定义 ====================

  @override
  Color get light => const Color(0xFFFFB7CD); // 浅粉 - 渐变起始

  @override
  Color get medium => const Color.fromARGB(255, 255, 84, 138); // 主粉 - 按钮/激活态

  @override
  Color get dark => const Color.fromARGB(255, 239, 9, 109); // 深粉 - 渐变终点/边框

  @override
  Color get subtitleColor => medium;

  @override
  Color get dotColor => medium;

  // ==================== 背景渲染 ====================

  @override
  Widget buildBackground(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 渐变底色
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [light, dark],
            ),
          ),
        ),
        // 旋转图案
        const _RotatingImage(
          assetPath: AppAssets.maimaiBgPattern,
          duration: Duration(seconds: 240),
          scale: 3.5,
        ),
        const _RotatingImage(
          assetPath: AppAssets.maimaiCircleWhite,
          duration: Duration(seconds: 180),
          scale: 1.4,
          reverse: true,
        ),
        const _RotatingImage(
          assetPath: AppAssets.maimaiCircleYellow,
          duration: Duration(seconds: 280),
          scale: 1.7,
        ),
        const _RotatingImage(
          assetPath: AppAssets.maimaiCircleColorful,
          duration: Duration(seconds: 310),
          scale: 1.7,
          reverse: true,
        ),
        // 四角装饰
        Positioned(
          top: 0,
          left: 0,
          child: Image.asset(
            AppAssets.maimaiTopLeft,
            width: 200,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Image.asset(
            AppAssets.maimaiTopRight,
            width: MediaQuery.of(context).size.width * 0.4,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Image.asset(
            AppAssets.maimaiBottomLeft,
            width: MediaQuery.of(context).size.width * 0.4,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Image.asset(
            AppAssets.maimaiBottomRight,
            width: 200,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  // ==================== ThemeExtension 必需方法 ====================

  @override
  SkinExtension copyWith({
    Color? light,
    Color? medium,
    Color? dark,
    Color? subtitleColor,
    Color? dotColor,
  }) {
    return this; // 皮肤是常量，不需要复制
  }
}

// ==================== 内部旋转图片组件 ====================

class _RotatingImage extends StatefulWidget {
  final String assetPath;
  final Duration duration;
  final double scale;
  final bool reverse;

  const _RotatingImage({
    required this.assetPath,
    required this.duration,
    this.scale = 1.0,
    this.reverse = false,
  });

  @override
  State<_RotatingImage> createState() => _RotatingImageState();
}

class _RotatingImageState extends State<_RotatingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(_RotatingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double angle = _controller.value * 2 * 3.14159;
            return Transform.rotate(
              angle: widget.reverse ? -angle : angle,
              child: Transform.scale(scale: widget.scale, child: child!),
            );
          },
          child: Image.asset(widget.assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
