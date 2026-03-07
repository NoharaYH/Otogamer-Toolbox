import 'package:flutter/material.dart';

import '../mai/mai_music_provider.dart';
import '../shared/game_provider.dart';
import '../shared/navigation_provider.dart';
import '../../ui/design_system/theme/core/app_theme.dart';
import '../../ui/design_system/theme/special_theme/utage.dart';
import '../../ui/design_system/theme/theme_catalog.dart';

/// 单点计算并输出当前解析后的 [AppTheme]，
/// 供 RootPage 唯一消费，消除三处 Consumer2 重复计算与多次重建。
class RootThemeCoordinator {
  RootThemeCoordinator(
    this._gameProvider,
    this._maiMusicProvider,
    this._navProvider,
  ) : resolvedTheme = ValueNotifier(_compute(_gameProvider, _maiMusicProvider, _navProvider)) {
    _gameProvider.addListener(_recompute);
    _maiMusicProvider.addListener(_recompute);
    _navProvider.addListener(_recompute);
    _gameProvider.pageValueNotifier.addListener(_recompute);
  }

  final GameProvider _gameProvider;
  final MaiMusicProvider _maiMusicProvider;
  final NavigationProvider _navProvider;

  final ValueNotifier<AppTheme> resolvedTheme;

  void _recompute() {
    resolvedTheme.value = _compute(_gameProvider, _maiMusicProvider, _navProvider);
  }

  static AppTheme _compute(
    GameProvider gp,
    MaiMusicProvider maiMusicProvider,
    NavigationProvider nav,
  ) {
    if (gp.isThemeGlobal) {
      final baseSkin = ThemeCatalog.findThemeById(gp.activeSkinId);
      return gp.resolvedTheme(baseSkin);
    }
    final double t = gp.pageValueNotifier.value.clamp(0.0, 1.0);
    final isUtage = nav.currentTag == PageTag.musicData && maiMusicProvider.isUtageMode;
    final AppTheme maiSkin;
    if (isUtage) {
      maiSkin = const UtageTheme();
    } else {
      maiSkin = gp.resolvedTheme(ThemeCatalog.findThemeById(gp.maiSkinId));
    }
    final chuSkin = gp.resolvedTheme(ThemeCatalog.findThemeById(gp.chuSkinId));
    return maiSkin.lerp(chuSkin, t);
  }

  void dispose() {
    _gameProvider.removeListener(_recompute);
    _maiMusicProvider.removeListener(_recompute);
    _navProvider.removeListener(_recompute);
    _gameProvider.pageValueNotifier.removeListener(_recompute);
    resolvedTheme.dispose();
  }
}
