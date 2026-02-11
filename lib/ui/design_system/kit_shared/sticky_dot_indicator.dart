import 'package:flutter/material.dart';

class StickyDotIndicator extends StatelessWidget {
  final PageController controller;
  final int count;
  final Color activeColor;
  final Color inactiveColor;

  const StickyDotIndicator({
    super.key,
    required this.controller,
    required this.count,
    required this.activeColor,
    this.inactiveColor = Colors.grey, // Default inactive color
  });

  @override
  Widget build(BuildContext context) {
    const double dotSize = 8.0;
    const double spacing = 16.0;
    final double totalWidth = (count * dotSize) + ((count - 1) * spacing);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double page = _safePage;

        return SizedBox(
          width: totalWidth + 20,
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fixed Background Dots
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(count, (index) {
                  return Container(
                    width: dotSize,
                    height: dotSize,
                    margin: EdgeInsets.only(left: index == 0 ? 0 : spacing),
                    decoration: BoxDecoration(
                      color: inactiveColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              // Animated Worm
              CustomPaint(
                size: Size(totalWidth, dotSize),
                painter: _StickyDotPainter(
                  page: page,
                  color: activeColor,
                  dotSize: dotSize,
                  spacing: spacing,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double get _safePage {
    return controller.hasClients ? (controller.page ?? 0.0) : 0.0;
  }
}

class _StickyDotPainter extends CustomPainter {
  final double page;
  final Color color;
  final double dotSize;
  final double spacing;

  _StickyDotPainter({
    required this.page,
    required this.color,
    required this.dotSize,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double distance = dotSize + spacing;
    final double p = page.clamp(0.0, 1.0);

    // Calculate worm expansion/contraction logic
    // This logic mimics the "sticky" effect where the dot stretches to the next position

    // Default start position (relative to canvas origin)
    double startX = 0;

    // Animate Left edge (l) and Right edge (r) independently
    // l moves slower at first (sticky), then fast
    // r moves fast at first (stretch), then slower

    // Forward transition (0 -> 1) logic:
    double l =
        startX +
        distance * const Interval(0.5, 1.0, curve: Curves.easeOut).transform(p);
    double r =
        startX +
        dotSize +
        distance * const Interval(0.0, 0.5, curve: Curves.easeIn).transform(p);

    final RRect rect = RRect.fromLTRBR(
      l,
      0,
      r,
      dotSize,
      Radius.circular(dotSize / 2),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_StickyDotPainter oldDelegate) {
    return oldDelegate.page != page || oldDelegate.color != color;
  }
}
