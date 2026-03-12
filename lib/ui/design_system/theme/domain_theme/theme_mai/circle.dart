import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../../constants/assets.dart';

@GameTheme()
class CircleTheme extends AppTheme {
  const CircleTheme();

  @override
  ThemeDomain get domain => ThemeDomain.maimai;

  @override
  String get themeTitle => 'Circle';

  @override
  String get themeId => 'mai_circle';

  @override
  Color get light => const Color.fromARGB(255, 255, 226, 234);

  @override
  Color get basic => const Color.fromARGB(255, 255, 84, 138);

  // 严格遵循兜底规范，如果需要特定暗色可返回，但如果是文字色可能会被外部强制转为 #2d2d2d，
  // 视具体的渲染处而定，或者统一约束为不超过 #2d2d2d 的色域。
  @override
  Color get dark => const Color(0xFF333333);

  @override
  Color get subtitleColor => basic;

  @override
  Color get dotColor => basic;

  @override
  Widget buildBackground(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final bool isCompact = w < 600;

    // ── L1 纹理层（官网 500s 旋转；在 70% 基础上再放大 50%）──
    final double textureSide = math.max(w, h) * 1;

    // ── L2 焦点层 ──
    final double circleWhiteSize = isCompact ? 354.0 : 788.0;
    final double circleYellowSize = isCompact ? 576.0 : 1026.0;
    final double circleColorfulSize = isCompact ? 466.0 : 953.0;

    // ── L3 边角层 ──
    final double topLeftW = isCompact ? double.infinity : 853.0;
    final double topRightW = isCompact ? 162.0 : 316.0;
    final double bottomLeftW = isCompact ? 118.0 : 231.0;
    final double bottomRightW = isCompact ? double.infinity : 683.0;

    // ── L4 氛围层（官网尺寸两档；三个 tile 缩减 50%）──
    final double tileGreenW = (isCompact ? 80.0 : 216.0) * 0.5;
    final double tileGreenH = (isCompact ? 300.0 : 692.0) * 0.5;
    final double tilePurpleLeftW = (isCompact ? 70.0 : 192.0) * 0.5;
    final double tilePurpleLeftH = (isCompact ? 250.0 : 593.0) * 0.5;
    final double tilePurpleRightW = (isCompact ? 50.0 : 140.0) * 0.5;
    final double tilePurpleRightH = (isCompact ? 150.0 : 340.0) * 0.5;
    final double starPinkW = isCompact ? 26.0 : 90.0;
    final double starPinkH = isCompact ? 100.0 : 306.0;
    final double starYellowW = isCompact ? 37.0 : 64.0;
    final double starYellowH = isCompact ? 110.0 : 213.0;
    final double d3CubeW = isCompact ? 45.0 : 113.0;
    final double d3CubeH = isCompact ? 40.0 : 102.0;
    final double d3StarSmallW = isCompact ? 15.0 : 34.0;
    final double d3StarSmallH = isCompact ? 18.0 : 40.0;
    final double d3StarsW = isCompact ? 40.0 : 93.0;
    final double d3StarsH = isCompact ? 35.0 : 78.0;
    final double d3GloveBlueW = isCompact ? 30.0 : 69.0;
    final double d3GloveBlueH = isCompact ? 32.0 : 75.0;
    final double d3GlovePinkW = isCompact ? 56.0 : 108.0;
    final double d3GlovePinkH = isCompact ? 66.0 : 128.0;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        // L0 底色层
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [const Color(0xFFFFB7CD), const Color(0xFFEF096D)],
            ),
          ),
        ),
        // L1 纹理层（500s 旋转，无 scale）
        _TextureLayer(textureSide: textureSide),
        // L2 焦点层（固定尺寸，无 scale）
        _RotatingImage(
          assetPath: AppAssets.maimaiCircleWhite,
          duration: const Duration(seconds: 110),
          size: circleWhiteSize,
          reverse: true,
        ),
        _TiltingImage(
          assetPath: AppAssets.maimaiCircleYellow,
          duration: const Duration(seconds: 80),
          size: circleYellowSize,
        ),
        _RotatingImage(
          assetPath: AppAssets.maimaiCircleColorful,
          duration: const Duration(seconds: 100),
          size: circleColorfulSize,
          reverse: true,
        ),
        // L4 氛围层：垂直运动（循环时间 15±10s，速度放慢至 70%）；3D 环绕+自转
        _RiseAndFadeDecoration(
          assetPath: AppAssets.maimaiTileGreen,
          width: tileGreenW,
          height: tileGreenH,
          topRatio: 0.18,
          leftRatio: 0.02,
          duration: const Duration(milliseconds: 8570),
          delay: Duration.zero,
        ),
        _RiseAndFadeDecoration(
          assetPath: AppAssets.maimaiTilePurpleLeft,
          width: tilePurpleLeftW,
          height: tilePurpleLeftH,
          topRatio: 0.22,
          leftRatio: 0.16,
          duration: const Duration(milliseconds: 12860),
          delay: const Duration(milliseconds: 800),
        ),
        _RiseAndFadeDecoration(
          assetPath: AppAssets.maimaiTilePurpleRight,
          width: tilePurpleRightW,
          height: tilePurpleRightH,
          topRatio: 0.25,
          rightRatio: 0.03,
          duration: const Duration(milliseconds: 17140),
          delay: const Duration(milliseconds: 500),
        ),
        _RiseAndFadeDecoration(
          assetPath: AppAssets.maimaiStarPink,
          width: starPinkW,
          height: starPinkH,
          topRatio: 0.08,
          leftRatio: 0.10,
          duration: const Duration(milliseconds: 21430),
          delay: Duration.zero,
        ),
        _RiseAndFadeDecoration(
          assetPath: AppAssets.maimaiStarPink,
          width: starPinkW,
          height: starPinkH,
          topRatio: 0.14,
          rightRatio: 0.10,
          duration: const Duration(milliseconds: 25710),
          delay: const Duration(milliseconds: 400),
        ),
        _RiseAndFadeDecoration(
          assetPath: AppAssets.maimaiStarYellow,
          width: starYellowW,
          height: starYellowH,
          topRatio: 0.12,
          leftRatio: 0.06,
          duration: const Duration(milliseconds: 30000),
          delay: const Duration(milliseconds: 200),
        ),
        _RiseAndFadeDecoration(
          assetPath: AppAssets.maimaiStarYellow,
          width: starYellowW,
          height: starYellowH,
          topRatio: 0.16,
          rightRatio: 0.14,
          duration: const Duration(milliseconds: 34290),
          delay: const Duration(milliseconds: 600),
        ),
        _OrbitalDecoration(
          assetPath: AppAssets.maimai3dCube,
          width: d3CubeW,
          height: d3CubeH,
          orbitRadiusRatio: 0.28,
          orbitPhase: math.pi * 0.2,
          duration: const Duration(seconds: 25),
          reverse: true,
          spin: true,
        ),
        _OrbitalDecoration(
          assetPath: AppAssets.maimai3dStarSmall,
          width: d3StarSmallW,
          height: d3StarSmallH,
          orbitRadiusRatio: 0.30,
          orbitPhase: math.pi * 1.2,
          duration: const Duration(seconds: 15),
          spin: true,
        ),
        _OrbitalDecoration(
          assetPath: AppAssets.maimai3dStars,
          width: d3StarsW,
          height: d3StarsH,
          orbitRadiusRatio: 0.26,
          orbitPhase: math.pi * 0.6,
          duration: const Duration(seconds: 28),
          spin: true,
        ),
        _OrbitalDecoration(
          assetPath: AppAssets.maimai3dGloveBlue,
          width: d3GloveBlueW,
          height: d3GloveBlueH,
          orbitRadiusRatio: 0.34,
          orbitPhase: math.pi * 1.5,
          duration: const Duration(seconds: 20),
          reverse: true,
          spin: true,
        ),
        _OrbitalDecoration(
          assetPath: AppAssets.maimai3dGlovePink,
          width: d3GlovePinkW,
          height: d3GlovePinkH,
          orbitRadiusRatio: 0.30,
          orbitPhase: math.pi,
          duration: const Duration(seconds: 16),
          reverse: true,
          spin: true,
        ),
        // L3 边角层（置于最顶层）
        Positioned(
          top: 0,
          left: 0,
          child: SizedBox(
            width: topLeftW == double.infinity ? w : topLeftW,
            height: topLeftW == double.infinity ? 100.0 : null,
            child: Image.asset(
              AppAssets.maimaiTopLeft,
              width: topLeftW == double.infinity ? w : topLeftW,
              height: topLeftW == double.infinity ? 100.0 : null,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Image.asset(
            AppAssets.maimaiTopRight,
            width: topRightW,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Image.asset(
            AppAssets.maimaiBottomLeft,
            width: bottomLeftW,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: SizedBox(
            width: bottomRightW == double.infinity ? w : bottomRightW,
            height: bottomRightW == double.infinity ? 100.0 : null,
            child: Image.asset(
              AppAssets.maimaiBottomRight,
              width: bottomRightW == double.infinity ? w : bottomRightW,
              height: bottomRightW == double.infinity ? 100.0 : null,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  @override
  AppTheme copyWith({
    Color? light,
    Color? basic,
    Color? dark,
    Color? subtitleColor,
    Color? dotColor,
  }) {
    final safeDark = (dark != null && dark.computeLuminance() > 0.3)
        ? const Color(0xFF2D2D2D)
        : (dark ?? this.dark);
    return AppTheme.createDynamic(
      domainVal: domain,
      titleVal: themeTitle,
      idVal: themeId,
      lightColor: light ?? this.light,
      basicColor: basic ?? this.basic,
      darkColor: safeDark,
      subtitleColorVal: subtitleColor ?? this.subtitleColor,
      dotColorVal: dotColor ?? this.dotColor,
      baseTheme: this,
    );
  }
}

/// L1 纹理层：满屏旋转花纹，尺寸 textureSide = max(w,h)，500s 一圈，无 scale。
class _TextureLayer extends StatefulWidget {
  final double textureSide;

  const _TextureLayer({required this.textureSide});

  @override
  State<_TextureLayer> createState() => _TextureLayerState();
}

class _TextureLayerState extends State<_TextureLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 500),
    )..repeat();
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
        child: OverflowBox(
          minWidth: widget.textureSide,
          maxWidth: widget.textureSide,
          minHeight: widget.textureSide,
          maxHeight: widget.textureSide,
          alignment: Alignment.center,
          child: SizedBox(
            width: widget.textureSide,
            height: widget.textureSide,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) => Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: child,
              ),
              child: Image.asset(
                AppAssets.maimaiBgPattern,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RotatingImage extends StatefulWidget {
  final String assetPath;
  final Duration duration;
  final double size;
  final bool reverse;

  const _RotatingImage({
    required this.assetPath,
    required this.duration,
    required this.size,
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
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double angle = _controller.value * 2 * math.pi;
              return Transform.rotate(
                angle: widget.reverse ? -angle : angle,
                child: child!,
              );
            },
            child: Image.asset(widget.assetPath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

/// L2 黄环：±15° 往复 tilt，80s alternate，固定尺寸无 scale。
class _TiltingImage extends StatefulWidget {
  final String assetPath;
  final Duration duration;
  final double size;

  const _TiltingImage({
    required this.assetPath,
    required this.duration,
    required this.size,
  });

  @override
  State<_TiltingImage> createState() => _TiltingImageState();
}

class _TiltingImageState extends State<_TiltingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const double _tiltDegrees = 15.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
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
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) {
              final double angle =
                  (-_tiltDegrees + 2 * _tiltDegrees * _controller.value) *
                  math.pi /
                  180;
              return Transform.rotate(angle: angle, child: child!);
            },
            child: Image.asset(widget.assetPath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

/// L4 氛围层：从下到上单向循环（官网式 riseAndFade），各实例不同循环时间与轨迹。
class _RiseAndFadeDecoration extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;
  final double topRatio;
  final double? leftRatio;
  final double? rightRatio;
  final Duration duration;
  final Duration delay;

  const _RiseAndFadeDecoration({
    required this.assetPath,
    required this.width,
    required this.height,
    required this.topRatio,
    this.leftRatio,
    this.rightRatio,
    required this.duration,
    this.delay = Duration.zero,
  });

  @override
  State<_RiseAndFadeDecoration> createState() => _RiseAndFadeDecorationState();
}

class _RiseAndFadeDecorationState extends State<_RiseAndFadeDecoration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;

  /// 位移范围：从屏幕外下方到屏幕外上方，再重置（超出视口再消失）
  static const double _travelExtent = 1200.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _offset = Tween<double>(
      begin: _travelExtent,
      end: -_travelExtent,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.repeat();
      });
    } else {
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
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    return Positioned(
      top: h * widget.topRatio,
      left: widget.leftRatio != null ? w * widget.leftRatio! : null,
      right: widget.rightRatio != null ? w * widget.rightRatio! : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, _offset.value),
              child: child,
            ),
          );
        },
        child: Image.asset(
          widget.assetPath,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// L4 氛围层：仅旋转（固定位置 + 自转），3D 等未选中素材使用。
class _L4RotatingDecoration extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;
  final double topRatio;
  final double? leftRatio;
  final double? rightRatio;
  final Duration duration;
  final bool reverse;

  const _L4RotatingDecoration({
    required this.assetPath,
    required this.width,
    required this.height,
    required this.topRatio,
    this.leftRatio,
    this.rightRatio,
    required this.duration,
    this.reverse = false,
  });

  @override
  State<_L4RotatingDecoration> createState() => _L4RotatingDecorationState();
}

class _L4RotatingDecorationState extends State<_L4RotatingDecoration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    return Positioned(
      top: h * widget.topRatio,
      left: widget.leftRatio != null ? w * widget.leftRatio! : null,
      right: widget.rightRatio != null ? w * widget.rightRatio! : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final double angle =
              2 * math.pi * _controller.value * (widget.reverse ? -1 : 1);
          return Transform.rotate(angle: angle, child: child!);
        },
        child: Image.asset(
          widget.assetPath,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// L4 氛围层：环绕旋转（沿屏幕中心圆周轨道运动），可选自转；当前未使用，保留备选。
class _OrbitalDecoration extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;
  final double orbitRadiusRatio;
  final double orbitPhase;
  final Duration duration;
  final Duration delay;
  final bool reverse;
  final bool spin;

  const _OrbitalDecoration({
    required this.assetPath,
    required this.width,
    required this.height,
    required this.orbitRadiusRatio,
    this.orbitPhase = 0,
    required this.duration,
    this.delay = Duration.zero,
    this.reverse = false,
    this.spin = false,
  });

  @override
  State<_OrbitalDecoration> createState() => _OrbitalDecorationState();
}

class _OrbitalDecorationState extends State<_OrbitalDecoration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.repeat();
      });
    } else {
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
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final radius = math.min(w, h) * widget.orbitRadiusRatio;
    final centerX = w * 0.5;
    final centerY = h * 0.5;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final double orbitAngle =
            2 * math.pi * _controller.value * (widget.reverse ? -1 : 1) +
            widget.orbitPhase;
        final double left =
            centerX + radius * math.cos(orbitAngle) - widget.width * 0.5;
        final double top =
            centerY + radius * math.sin(orbitAngle) - widget.height * 0.5;
        final double spinAngle = widget.spin
            ? 2 * math.pi * _controller.value * (widget.reverse ? -1 : 1)
            : 0.0;

        Widget content = child!;
        if (widget.spin) {
          content = Transform.rotate(angle: spinAngle, child: content);
        }
        return Positioned(left: left, top: top, child: content);
      },
      child: Image.asset(
        widget.assetPath,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
      ),
    );
  }
}
