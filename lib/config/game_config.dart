import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';

enum GameType {
  maimai('maimai', '舞萌 DX'),
  chunithm('chunithm', '中二节奏');

  final String id;
  final String label;
  const GameType(this.id, this.label);
}

class GameThemeConfig {
  final GameType gameType;
  final Color primaryColor;
  final Color secondaryColor;
  final Color containerColor;
  final Color shadowColor;
  final Color gradientStart;
  final String logoPath;

  const GameThemeConfig({
    required this.gameType,
    required this.primaryColor,
    required this.secondaryColor,
    required this.containerColor,
    required this.shadowColor,
    required this.gradientStart,
    required this.logoPath,
  });

  static const maimai = GameThemeConfig(
    gameType: GameType.maimai,
    primaryColor: AppColors.maimaiPinkDark,
    secondaryColor: AppColors.maimaiPinkLight,
    containerColor: AppColors.maimaiContainer,
    shadowColor: AppColors.maimaiShadow,
    gradientStart: AppColors.maimaiGradientStart,
    logoPath: AppAssets.logoMaimai,
  );

  static const chunithm = GameThemeConfig(
    gameType: GameType.chunithm,
    primaryColor: AppColors.chunithmBlueDark,
    secondaryColor: AppColors.chunithmBlueLight,
    containerColor: AppColors.chunithmContainer,
    shadowColor: AppColors.chunithmShadow,
    gradientStart: AppColors.chunithmGradientStart,
    logoPath: AppAssets.logoChunithm,
  );

  static List<GameThemeConfig> get all => [maimai, chunithm];
}
