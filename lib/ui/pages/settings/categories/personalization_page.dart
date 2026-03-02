import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../application/shared/game_provider.dart';
import '../../../design_system/constants/sizes.dart';
import '../../../design_system/constants/colors.dart';
import '../../../design_system/kit_shared/kit_bounce_scaler.dart';
import '../../../design_system/visual_skins/skin_extension.dart';
import '../../../design_system/kit_setting/setting_card.dart';
import '../../../design_system/kit_setting/setting_menu.dart';

/// 设置页: 个性化专页 (v4.0 - Injection Protocol)
/// 遵循 SECONDARY_PAGE_SPEC 与 CARD_PROTOCOL。
class PersonalizationPage extends StatelessWidget {
  const PersonalizationPage({super.key, Color? themeColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('personalization_page_view'),
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(
        horizontal: UiSizes.getHorizontalMargin(context),
        vertical: 20,
      ),
      child: Column(
        children: [
          // 卡片 A: 皮肤系统
          SettingCard(
            index: 1,
            title: "皮肤系统",
            icon: Icons.palette_outlined,
            child: const SkinSystemAssembly(),
          ),
        ],
      ),
    );
  }
}

/// SkinSystemAssembly: 皮肤切换主辖件。
/// 渲染色通过 SkinExtension.medium 注入，不接收硬传参。
class SkinSystemAssembly extends StatelessWidget {
  const SkinSystemAssembly({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final skin = Theme.of(context).extension<SkinExtension>()!;
    final accentColor = skin.medium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 顶部属性选择
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "选择皮肤属性",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: UiColors.grey700,
              ),
            ),
            SettingSegmentedSwitch(
              labels: const ['全局', '独立'],
              selectedIndex: gameProvider.isIndependentSkin ? 1 : 0,
              onChanged: (i) => gameProvider.setIndependentSkin(i == 1),
              accentColor: accentColor,
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // 2. 根据模式显示不同内容 (渐隐 + 变高度 -> 浮现策略)
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren.map(
                    (e) => Positioned(top: 0, left: 0, right: 0, child: e),
                  ),
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
                ),
                child: child,
              );
            },
            child: !gameProvider.isIndependentSkin
                ? _buildGlobalSection(
                    context,
                    gameProvider,
                    accentColor,
                    key: const ValueKey('global_skin_config'),
                  )
                : _buildIndependentSection(
                    context,
                    gameProvider,
                    accentColor,
                    key: const ValueKey('independent_skin_config'),
                  ),
          ),
        ),
      ],
    );
  }

  // --- 全局配置区 ---
  Widget _buildGlobalSection(
    BuildContext context,
    GameProvider provider,
    Color accentColor, {
    Key? key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubTitle("当前全局皮肤"),
        const SizedBox(height: 8),
        SettingMenu<String>(
          options: const ['default', 'maimai_dx', 'chunithm'],
          labels: const ['默认星空', '舞萌 DX', '中二节奏'],
          current: provider.globalSkin,
          onSelect: provider.setGlobalSkin,
          accentColor: accentColor,
        ),
        const SizedBox(height: 20),
        _buildSubTitle("自定义主题色"),
        const SizedBox(height: 12),
        _buildColorPicker(
          currentColor: provider.globalThemeColor,
          onColorChanged: provider.setGlobalThemeColor,
        ),
      ],
    );
  }

  // --- 独立配置区 ---
  Widget _buildIndependentSection(
    BuildContext context,
    GameProvider provider,
    Color accentColor, {
    Key? key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubTitle("舞萌 DX 独立配置"),
        const SizedBox(height: 8),
        SettingMenu<String>(
          options: const ['maimai_dx', 'default'],
          labels: const ['标准版', '星空版'],
          current: provider.maimaiSkin,
          onSelect: provider.setMaimaiSkin,
          accentColor: accentColor,
        ),
        const SizedBox(height: 12),
        _buildColorPicker(
          currentColor: provider.maimaiThemeColor,
          onColorChanged: provider.setMaimaiThemeColor,
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        _buildSubTitle("中二节奏 独立配置"),
        const SizedBox(height: 8),
        SettingMenu<String>(
          options: const ['chunithm', 'default'],
          labels: const ['标准版', '星空版'],
          current: provider.chunithmSkin,
          onSelect: provider.setChunithmSkin,
          accentColor: accentColor,
        ),
        const SizedBox(height: 12),
        _buildColorPicker(
          currentColor: provider.chunithmThemeColor,
          onColorChanged: provider.setChunithmThemeColor,
        ),
      ],
    );
  }

  Widget _buildSubTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w900,
        color: UiColors.grey600,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildColorPicker({
    required Color currentColor,
    required Function(Color) onColorChanged,
  }) {
    final List<Color> presets = [
      Colors.blue,
      Colors.pink,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.redAccent,
      const Color(0xFF333333),
    ];

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: presets.map((color) {
              final isSelected = currentColor.value == color.value;
              return KitBounceScaler(
                onTap: () => onColorChanged(color),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
