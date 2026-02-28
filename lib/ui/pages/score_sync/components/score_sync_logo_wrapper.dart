import 'package:flutter/material.dart';
import '../../../design_system/constants/sizes.dart';

/// A reusable wrapper for the game logo and content area on sync pages.
class ScoreSyncLogoWrapper extends StatelessWidget {
  final String logoPath;
  final String subtitle;
  final Color themeColor;
  final Widget child;

  const ScoreSyncLogoWrapper({
    super.key,
    required this.logoPath,
    required this.subtitle,
    required this.themeColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final topMargin = UiSizes.getTopMarginWithSafeArea(context);
    return Padding(
      padding: UiSizes.getPageContentPadding(context).copyWith(top: topMargin),
      child: Column(
        children: [
          // Logo Area with Watermark
          SizedBox(
            height: UiSizes.logoAreaHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Watermark Text (Behind)
                Positioned(
                  top: UiSizes.spaceXL,
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'GameFont',
                      fontSize: 34,
                      fontWeight: FontWeight.normal,
                      color: themeColor.withValues(alpha: 0.2),
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                // Logo Image (In Front)
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    logoPath,
                    height: UiSizes.logoHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: UiSizes.atomicComponentGap),
          Flexible(fit: FlexFit.loose, child: child),
        ],
      ),
    );
  }
}
