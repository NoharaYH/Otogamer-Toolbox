import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/shared/game_provider.dart';
import '../../../application/shared/navigation_provider.dart';
import 'music_data/music_data_page.dart';
import 'score_sync/score_sync_page.dart';
import 'settings/settings_page.dart';
import '../design_system/kit_navigation/nav_deck_overlay.dart';
import '../design_system/constants/sizes.dart';
import '../design_system/visual_skins/implementations/defaut_skin/star_background.dart';
import '../design_system/kit_shared/kit_action_circle.dart';
import '../design_system/page_shell.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      backgroundOverride: AnimatedBuilder(
        animation: context.read<GameProvider>().pageValueNotifier,
        builder: (context, _) {
          return const StarBackgroundSkin().buildBackground(context);
        },
      ),
      child: Stack(
        children: [
          // 1. 业务内容层：根据 Provider 挂载各页
          // 注意这里没有注入 Theme，原先的 ScoreSyncPage/MusicDataPage 里自带了 Theme 生成
          Consumer<NavigationProvider>(
            builder: (context, nav, child) {
              Widget page;
              switch (nav.currentTag) {
                case PageTag.scoreSync:
                  page = const ScoreSyncPage(key: ValueKey('scoreSync'));
                  break;
                case PageTag.musicData:
                  page = const MusicDataPage(key: ValueKey('musicData'));
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
                  return FadeTransition(opacity: animation, child: child);
                },
                child: page,
              );
            },
          ),

          // 2. 侧边栏隐形呼出热区 (左侧缩限到 4%)
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
                      nav.openDeck(anchorY: details.globalPosition.dy);
                    }
                  },
                );
              },
            ),
          ),

          // 3. 全局页眉操作区 (蓝色框位置)
          // 动态监听滑动以更新主题色
          AnimatedBuilder(
            animation: context.read<GameProvider>().pageValueNotifier,
            builder: (context, _) {
              const skin = StarBackgroundSkin();
              final themeColor = skin.medium;

              return Positioned(
                // 按钮回归玻璃层内部腹地。
                // 现设定距离边缘 12.0pt 的防区距离。
                top: UiSizes.getTopMarginWithSafeArea(context) + 12.0,
                right: UiSizes.getHorizontalMargin(context) + 12.0,
                child: Consumer<NavigationProvider>(
                  builder: (context, nav, child) {
                    // 当处于设置页面时，隐藏顶部的几个操作按钮
                    if (nav.isSettingsOpen) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      // 去除额外 padding，方便精确定位
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Settings 圆形图标
                          KitActionCircle(
                            icon: Icons.settings,
                            color: themeColor,
                            onTap: () => nav.openSettings(),
                          ),
                          const SizedBox(width: UiSizes.spaceS),
                          // NavDeck 菜单圆形图标
                          Builder(
                            builder: (btnCtx) => KitActionCircle(
                              icon: Icons
                                  .menu_open, // Or whatever icon you prefer
                              color: themeColor,
                              onTap: () {
                                final RenderBox box =
                                    btnCtx.findRenderObject() as RenderBox;
                                final position = box.localToGlobal(Offset.zero);
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
              );
            },
          ),

          // 4. 悬浮胶囊覆盖层 (自带 50% 变暗幕布)
          // 使其也能够响应主题过渡
          AnimatedBuilder(
            animation: context.read<GameProvider>().pageValueNotifier,
            builder: (context, _) {
              const skin = StarBackgroundSkin();

              return Theme(
                data: Theme.of(context).copyWith(extensions: [skin]),
                child: const Positioned.fill(child: NavDeckOverlay()),
              );
            },
          ),

          // 5. 设置页叠加层 (全屏覆盖但半透明背景)
          Consumer<NavigationProvider>(
            builder: (context, nav, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
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
