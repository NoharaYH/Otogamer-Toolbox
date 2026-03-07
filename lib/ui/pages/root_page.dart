import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../../application/coordinators/root_theme_coordinator.dart';
import '../../../application/shared/game_provider.dart';
import '../../../application/shared/navigation_provider.dart';
import 'music_data/music_data_page.dart';
import 'score_sync/score_sync_page.dart';
import 'settings/settings_page.dart';
import '../design_system/kit_navigation/nav_deck_overlay.dart';
import '../design_system/constants/sizes.dart';
import '../design_system/kit_shared/kit_action_circle.dart';
import '../design_system/page_shell.dart';
import '../design_system/theme/core/app_theme.dart';

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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          RepaintBoundary(
            key: _repaintBoundaryKey,
            child: ValueListenableBuilder<AppTheme>(
              valueListenable: coordinator.resolvedTheme,
              builder: (context, theme, _) {
                return PageShell(
                  backgroundOverride: theme.buildBackground(context),
                  child: Stack(
                    children: [
                      Consumer<NavigationProvider>(
                        builder: (context, nav, child) {
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
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: MediaQuery.of(context).size.width * 0.04,
                        child: Consumer<NavigationProvider>(
                          builder: (context, nav, child) {
                            return GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onPanUpdate: (details) {
                                if (details.delta.dx > 5 && !nav.isDeckOpen) {
                                  nav.openDeck(
                                    anchorY: details.globalPosition.dy,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: UiSizes.getTopMarginWithSafeArea(context) + 12.0,
                        right: UiSizes.getHorizontalMargin(context) + 12.0,
                        child: Consumer<NavigationProvider>(
                          builder: (context, nav, child) {
                            final themeColor = theme.basic;
                            return Container(
                              padding: EdgeInsets.zero,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  KitActionCircle(
                                    icon: Icons.settings,
                                    color: themeColor,
                                    onTap: () => nav.openSettings(),
                                  ),
                                  const SizedBox(width: UiSizes.spaceS),
                                  Builder(
                                    builder: (btnCtx) => KitActionCircle(
                                      icon: Icons.menu_open,
                                      color: themeColor,
                                      onTap: () {
                                        final RenderBox box = btnCtx
                                            .findRenderObject() as RenderBox;
                                        final position =
                                            box.localToGlobal(Offset.zero);
                                        nav.openDeck(
                                          anchorY: position.dy + box.size.height,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          extensions: [theme],
                        ),
                        child: const Positioned.fill(
                          child: NavDeckOverlay(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Consumer<NavigationProvider>(
            builder: (context, nav, child) {
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
