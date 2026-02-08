import 'package:flutter/material.dart';
import '../../constants/app_assets.dart';

class ChunithmBackground extends StatelessWidget {
  const ChunithmBackground({super.key});

  @override
  Widget build(BuildContext context) {
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
}
