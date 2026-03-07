import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mai/mai_music_provider.dart';
import '../shared/game_provider.dart';
import '../shared/navigation_provider.dart';
import 'root_theme_coordinator.dart';

/// 在拥有 GameProvider/MaiMusicProvider/NavigationProvider 的树下创建并提供 [RootThemeCoordinator]，
/// 供 RootPage 单点消费主题，生命周期与子树一致。
class RootThemeScope extends StatefulWidget {
  const RootThemeScope({super.key, required this.child});

  final Widget child;

  @override
  State<RootThemeScope> createState() => _RootThemeScopeState();
}

class _RootThemeScopeState extends State<RootThemeScope> {
  RootThemeCoordinator? _coordinator;

  @override
  void dispose() {
    _coordinator?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _coordinator ??= RootThemeCoordinator(
      context.read<GameProvider>(),
      context.read<MaiMusicProvider>(),
      context.read<NavigationProvider>(),
    );
    return Provider<RootThemeCoordinator>.value(
      value: _coordinator!,
      child: widget.child,
    );
  }
}
