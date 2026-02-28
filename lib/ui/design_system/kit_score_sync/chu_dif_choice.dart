import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../kit_shared/confirm_button.dart';
import '../kit_shared/kit_bounce_scaler.dart';

// ============================================================
// ============== 中二专属：难度选择器 =========================
// ============================================================

class ChuDifChoice extends StatefulWidget {
  final ValueChanged<Set<int>> onImport;
  final bool isLoading;
  final bool isDisabled;

  const ChuDifChoice({
    super.key,
    required this.onImport,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  State<ChuDifChoice> createState() => _ChuDifChoiceState();
}

class _ChuDifChoiceState extends State<ChuDifChoice> {
  // 0: BASIC, 1: ADVANCED, 2: EXPERT, 3: MASTER, 4: ULTIMA, 5: WORLD'S END
  final Set<int> _selectedDifficulties = {0, 1, 2, 3, 4, 5};

  final List<Map<String, dynamic>> _difficulties = [
    {'name': 'BASIC', 'abbr': 'BAS', 'color': const Color(0xFF2dbd51)},
    {'name': 'ADVANCED', 'abbr': 'ADV', 'color': const Color(0xFFe87628)},
    {'name': 'EXPERT', 'abbr': 'EXP', 'color': const Color(0xFFd52d2c)},
    {'name': 'MASTER', 'abbr': 'MAS', 'color': const Color(0xFFa103d3)},
    {'name': 'ULTIMA', 'abbr': 'ULT', 'color': const Color(0xFF1A1A1A)},
    {'name': "WORLD'S END", 'abbr': 'WE', 'color': const Color(0xFFFF6FFD)},
  ];

  void _toggleDifficulty(int index) {
    setState(() {
      if (_selectedDifficulties.contains(index)) {
        _selectedDifficulties.remove(index);
      } else {
        _selectedDifficulties.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IgnorePointer(
          ignoring: widget.isLoading || widget.isDisabled,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 150),
            tween: Tween<double>(
              begin: (widget.isLoading || widget.isDisabled) ? 1.0 : 0.0,
              end: (widget.isLoading || widget.isDisabled) ? 1.0 : 0.0,
            ),
            builder: (context, value, child) {
              return ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Color.lerp(
                    UiColors.transparent,
                    UiColors.disabledMask,
                    value,
                  )!,
                  BlendMode.srcATop,
                ),
                child: child,
              );
            },
            child: GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: UiSizes.spaceS,
                crossAxisSpacing: UiSizes.spaceS,
                childAspectRatio: 3.125, // 2.5 / 0.8 = 3.125，高度缩减 20%
              ),
              itemCount: _difficulties.length,
              itemBuilder: (context, index) {
                final difficulty = _difficulties[index];
                final isSelected = _selectedDifficulties.contains(index);

                return _ChuDifficultyButton(
                  difficulty: difficulty,
                  isSelected: isSelected,
                  onTap: () => _toggleDifficulty(index),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: UiSizes.atomicComponentGap),
        ConfirmButton(
          text: '开始导入',
          state: widget.isLoading
              ? ConfirmButtonState.loading
              : ConfirmButtonState.ready,
          onPressed: (_selectedDifficulties.isEmpty || widget.isDisabled)
              ? null
              : () => widget.onImport(_selectedDifficulties),
        ),
      ],
    );
  }
}

class _ChuDifficultyButton extends StatefulWidget {
  final Map<String, dynamic> difficulty;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ChuDifficultyButton({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ChuDifficultyButton> createState() => _ChuDifficultyButtonState();
}

class _ChuDifficultyButtonState extends State<_ChuDifficultyButton> {
  // 原始矩阵 (Identity)
  static const List<double> _identityMatrix = [
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  // 变暗矩阵 (Saturation 50% + Brightness 50%)
  static const List<double> _dimmedMatrix = [
    0.303,
    0.179,
    0.018,
    0,
    0,
    0.053,
    0.429,
    0.018,
    0,
    0,
    0.053,
    0.179,
    0.268,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  List<double> _lerpMatrix(double t) {
    return List.generate(20, (index) {
      return _identityMatrix[index] +
          (_dimmedMatrix[index] - _identityMatrix[index]) * t;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.difficulty['color'] as Color;
    final name = widget.difficulty['name'] as String;
    final bool isWorldEnd = name.contains("WORLD'S END");
    final bool isUltima = name.contains("ULTIMA");

    // 描边颜色逻辑更新
    Color borderColor;
    if (isUltima) {
      borderColor = Colors.black;
    } else if (isWorldEnd) {
      borderColor = const Color(0xFF19388A);
    } else {
      borderColor = color;
    }

    return KitBounceScaler(
      onTap: widget.onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: widget.isSelected ? 0.0 : 1.0,
          end: widget.isSelected ? 0.0 : 1.0,
        ),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return ColorFiltered(
            colorFilter: ColorFilter.matrix(_lerpMatrix(value)),
            child: Container(
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.zero, // 圆角改为 0
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4.5), // 外层边框厚度
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                ),
                padding: const EdgeInsets.all(1.2), // 内层白色边框厚度
                child: Container(
                  // 核心背景区域，圆角同样为 0
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 背景色块区域
                      if (isWorldEnd)
                        const _WorldEndBackground()
                      else if (isUltima)
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [
                                0.0,
                                0.41,
                                0.74,
                                1.0,
                              ], // 基于 SVG offset 反转 (1-x)
                              colors: [
                                Color(
                                  0xFFFF607A,
                                ), // stop-color="rgb(255,96,122)"
                                Color(
                                  0xFFE5121D,
                                ), // stop-color="rgb(229,18,29)"
                                Color(
                                  0xFF8D0A0F,
                                ), // stop-color="rgb(141,10,15)"
                                Color(0xFF340100), // stop-color="rgb(52,1,0)"
                              ],
                            ),
                          ),
                        )
                      else
                        Container(color: color),

                      // 文字标识
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18, // 放大文字尺寸
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'MorisawaUD',
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1.5),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 形状枚举标识
enum ArcadeShape { top, right, bottom, left }

/// 自定义多边形裁剪器 (中二街机分割风格)
class ArcadeShapeClipper extends CustomClipper<Path> {
  final ArcadeShape shape;
  final double offset;

  ArcadeShapeClipper(this.shape, this.offset);

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    switch (shape) {
      case ArcadeShape.top:
        path.moveTo(0, 0);
        path.lineTo(w, 0);
        path.lineTo(w - offset, offset);
        path.lineTo(offset, offset);
        path.close();
        break;
      case ArcadeShape.right:
        path.moveTo(w, 0);
        path.lineTo(w, h);
        path.lineTo(w - offset, offset);
        path.close();
        break;
      case ArcadeShape.bottom:
        path.moveTo(offset, offset);
        path.lineTo(w - offset, offset);
        path.lineTo(w, h);
        path.lineTo(0, h);
        path.close();
        break;
      case ArcadeShape.left:
        path.moveTo(0, 0);
        path.lineTo(0, h);
        path.lineTo(offset, offset);
        path.close();
        break;
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// WORLD'S END 专属背景组件
class _WorldEndBackground extends StatelessWidget {
  const _WorldEndBackground();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double offset = constraints.maxHeight / 2;
        return Stack(
          fit: StackFit.expand,
          children: [
            // 顶部梯形 (红->黄)
            ClipPath(
              clipper: ArcadeShapeClipper(ArcadeShape.top, offset),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFFEA2D2E), Color(0xFFF7B400)],
                  ),
                ),
              ),
            ),
            // 右侧直角等腰三角形 (绿->蓝)
            ClipPath(
              clipper: ArcadeShapeClipper(ArcadeShape.right, offset),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFA3D221), Color(0xFF0072B8)],
                  ),
                ),
              ),
            ),
            // 底部梯形 (青->深蓝)
            ClipPath(
              clipper: ArcadeShapeClipper(ArcadeShape.bottom, offset),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF00AEEF), Color(0xFF0C4DA2)],
                  ),
                ),
              ),
            ),
            // 左侧直角等腰三角形 (紫->深紫)
            ClipPath(
              clipper: ArcadeShapeClipper(ArcadeShape.left, offset),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF9D005D), Color(0xFF2F3293)],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
