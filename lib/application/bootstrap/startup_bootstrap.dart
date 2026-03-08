import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/game_provider.dart';
import '../shared/navigation_provider.dart';

/// 在应用根执行一次启动偏好初始化并注入 initialTag，仅冷启动生效。
/// 置于 MultiProvider 之下，确保可 read GameProvider / NavigationProvider。
///
/// 不阻塞渲染，init 完成后由 carousel 页面监听 currentIndex 并同步 PageController。
class StartupBootstrap extends StatefulWidget {
  const StartupBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<StartupBootstrap> createState() => _StartupBootstrapState();
}

class _StartupBootstrapState extends State<StartupBootstrap> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runOnce());
  }

  void _runOnce() {
    if (_done) return;
    _done = true;
    final gp = context.read<GameProvider>();
    final nav = context.read<NavigationProvider>();
    gp.init().then((initialTag) {
      if (mounted) nav.setInitialTag(initialTag);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
