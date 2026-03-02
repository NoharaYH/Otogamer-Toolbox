import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../application/shared/game_provider.dart';
import '../../../../application/shared/game_provider.dart' show StartupPagePref;
import '../../../design_system/constants/sizes.dart';
import '../../../design_system/constants/strings.dart';
import '../../../design_system/visual_skins/skin_extension.dart';
import '../../../design_system/kit_setting/setting_card.dart';
import '../../../design_system/kit_setting/setting_menu.dart';

/// 设置页: 应用设置专页 (v2.0 - Injection Protocol)
/// 专注于应用流程控制（如启动页偏好设置）。
class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key, Color? themeColor});

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
          SettingCard(
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

/// StartupPageMenu: 启动页选择，接入 SettingMenu 原子套件。
class StartupPageMenu extends StatelessWidget {
  const StartupPageMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final skin = Theme.of(context).extension<SkinExtension>()!;

    final prefs = [
      StartupPagePref.last,
      StartupPagePref.mai,
      StartupPagePref.chu,
    ];
    final labels = [
      UiStrings.startupLast,
      UiStrings.startupMai,
      UiStrings.startupChu,
    ];

    return SettingMenu<StartupPagePref>(
      options: prefs,
      labels: labels,
      current: gameProvider.startupPref,
      onSelect: gameProvider.setStartupPref,
      accentColor: skin.medium,
      leadingIcon: Icons.touch_app_outlined,
    );
  }
}
