import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../application/coordinators/resolved_theme_bundle.dart';
import '../../../application/coordinators/root_theme_coordinator.dart';
import '../../../application/shared/game_provider.dart';
import '../../../application/shared/navigation_provider.dart';
import 'music_data/music_data_page.dart';
import 'score_sync/score_sync_page.dart';
import 'settings/settings_page.dart';
import '../design_system/otokit_responsive_shell.dart';
import '../design_system/page_shell.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> with WidgetsBindingObserver {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NavigationProvider>().captureTask = _captureToSnapshot;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final nav = context.read<NavigationProvider>();
      context.read<GameProvider>().saveLastActiveState(nav.currentTag);
    }
  }

  Future<ui.Image?> _captureToSnapshot() async {
    try {
      final boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      return await boundary.toImage(pixelRatio: 1.0);
    } catch (e) {
      debugPrint('Snapshot Capture Failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = context.read<RootThemeCoordinator>();
    final glassConfig = context.watch<GameProvider>().glassOverlayPrefs;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          RepaintBoundary(
            key: _repaintBoundaryKey,
            child: ValueListenableBuilder<ResolvedThemeBundle>(
              valueListenable: coordinator.resolvedBundle,
              builder: (context, bundle, _) {
                final isCompact =
                    MediaQuery.sizeOf(context).width < 600;
                return PageShell(
                  backgroundOverride: bundle.buildBackground(context),
                  showGlassOverlay: isCompact,
                  glassOverlayConfig: glassConfig,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      extensions: [bundle.theme],
                    ),
                    child: OtokitResponsiveShell(
                      glassOverlayConfig: glassConfig,
                      child: Consumer<NavigationProvider>(
                        builder: (context, nav, _) {
                          final Widget page;
                          switch (nav.currentTag) {
                            case PageTag.scoreSync:
                              page = const ScoreSyncPage(
                                key: ValueKey('scoreSync'),
                              );
                              break;
                            case PageTag.musicData:
                              page = const MusicDataPage(
                                key: ValueKey('musicData'),
                              );
                              break;
                          }
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: const Interval(
                              0.5,
                              1.0,
                              curve: Curves.easeOutCubic,
                            ),
                            switchOutCurve: const Interval(
                              0.5,
                              1.0,
                              curve: Curves.easeInCubic,
                            ),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: page,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Consumer<NavigationProvider>(
            builder: (context, nav, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: nav.isSettingsOpen
                    ? const SettingsPage(key: ValueKey('settings_overlay'))
                    : const SizedBox.shrink(key: ValueKey('empty_overlay')),
              );
            },
          ),
        ],
      ),
    );
  }
}
