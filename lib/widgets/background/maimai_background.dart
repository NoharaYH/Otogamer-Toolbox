import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import 'rotating_image.dart';

class MaimaiBackground extends StatelessWidget {
  const MaimaiBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient Base
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [AppColors.maimaiPinkLight, AppColors.maimaiPinkDark],
            ),
          ),
        ),
        // Rotating Patterns
        const RotatingImage(
          assetPath: AppAssets.maimaiBgPattern,
          duration: Duration(seconds: 240),
          scale: 3.5,
        ),
        const RotatingImage(
          assetPath: AppAssets.maimaiCircleWhite,
          duration: Duration(seconds: 180),
          scale: 1.4,
          reverse: true,
        ),
        const RotatingImage(
          assetPath: AppAssets.maimaiCircleYellow,
          duration: Duration(seconds: 280),
          scale: 1.7,
        ),
        const RotatingImage(
          assetPath: AppAssets.maimaiCircleColorful,
          duration: Duration(seconds: 310),
          scale: 1.7,
          reverse: true,
        ),
        // Corner Decorations
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
}
