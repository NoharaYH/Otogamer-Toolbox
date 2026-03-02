import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../application/shared/game_provider.dart';
import '../../../../application/shared/game_provider.dart' show StartupPagePref;
import '../../../design_system/constants/sizes.dart';
import '../../../design_system/constants/colors.dart';
import '../../../design_system/constants/strings.dart';
import '../../../design_system/kit_shared/kit_staggered_entrance.dart';
import '../../../design_system/kit_shared/kit_bounce_scaler.dart';
import '../../../design_system/visual_skins/skin_extension.dart';

/// 设置页: 应用设置专页 (v1.5)
/// 专注于应用流程控制（如启动页偏好设置）。
class AppSettingsPage extends StatelessWidget {
  final Color themeColor;
  const AppSettingsPage({super.key, this.themeColor = Colors.blue});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('app_settings_page_view'),
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(
        horizontal: UiSizes.getHorizontalMargin(context),
        vertical: 20,
      ),
      child: Column(
        children: [
          // 卡片 A: 启动页设置
          _SettingsCard(
            index: 1,
            title: "启动页偏好",
            icon: Icons.launch_outlined,
            child: const StartupPageMenu(),
          ),
        ],
      ),
    );
  }
}

/// 标准设置卡片包装器 (遵循 CARD_PROTOCOL)
class _SettingsCard extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsCard({
    required this.index,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return KitStaggeredEntrance(
      index: index,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(UiSizes.cardContentPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(UiSizes.cardRadius),
          boxShadow: [
            BoxShadow(
              color: UiColors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: UiColors.grey700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: UiColors.grey800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// StartupPageMenu: 紧凑型单选菜单
class StartupPageMenu extends StatelessWidget {
  const StartupPageMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final skin = Theme.of(context).extension<SkinExtension>()!;

    final options = [
      (title: UiStrings.startupLast, pref: StartupPagePref.last),
      (title: UiStrings.startupMai, pref: StartupPagePref.mai),
      (title: UiStrings.startupChu, pref: StartupPagePref.chu),
    ];

    final currentTitle = options
        .firstWhere((o) => o.pref == gameProvider.startupPref)
        .title;

    return KitBounceScaler(
      onTap: () async {
        final result = await showMenu<StartupPagePref>(
          context: context,
          position: _getMenuPosition(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white.withValues(alpha: 0.95),
          items: options
              .map(
                (o) => PopupMenuItem(
                  value: o.pref,
                  child: Row(
                    children: [
                      Icon(
                        o.pref == gameProvider.startupPref
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: o.pref == gameProvider.startupPref
                            ? skin.medium
                            : UiColors.grey400,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        o.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: o.pref == gameProvider.startupPref
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: o.pref == gameProvider.startupPref
                              ? skin.medium
                              : UiColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );

        if (result != null) {
          gameProvider.setStartupPref(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: UiColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.touch_app_outlined,
              size: 18,
              color: UiColors.grey600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "显示页面：$currentTitle",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: UiColors.grey700,
                ),
              ),
            ),
            const Icon(Icons.unfold_more, size: 18, color: UiColors.grey400),
          ],
        ),
      ),
    );
  }

  RelativeRect _getMenuPosition(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    return RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + renderBox.size.height,
      offset.dx + renderBox.size.width,
      offset.dy + renderBox.size.height + 200,
    );
  }
}
