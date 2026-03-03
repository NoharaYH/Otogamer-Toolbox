import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../../constants/assets.dart';

@GameTheme()
class VerseTheme extends AppTheme {
  const VerseTheme();

  @override
  ThemeDomain get domain => ThemeDomain.chunithm;

  @override
  String get themeTitle => 'Verse';

  @override
  String get themeId => 'chu_verse';

  @override
  Color get light => const Color.fromARGB(255, 165, 208, 255);

  @override
  Color get medium => const Color.fromARGB(255, 111, 140, 255);

  @override
  Color get dark => const Color.fromARGB(255, 0, 98, 255);

  @override
  Color get subtitleColor => medium;

  @override
  Color get dotColor => medium;

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

  @override
  AppTheme copyWith({
    Color? light,
    Color? medium,
    Color? dark,
    Color? subtitleColor,
    Color? dotColor,
  }) {
    return AppTheme.createDynamic(
      domainVal: domain,
      titleVal: themeTitle,
      idVal: themeId,
      lightColor: light ?? this.light,
      mediumColor: medium ?? this.medium,
      darkColor: dark ?? this.dark,
      subtitleColorVal: subtitleColor ?? this.subtitleColor,
      dotColorVal: dotColor ?? this.dotColor,
      baseTheme: this,
    );
  }
}
