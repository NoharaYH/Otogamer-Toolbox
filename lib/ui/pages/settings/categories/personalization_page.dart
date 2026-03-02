import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../application/shared/game_provider.dart';
import '../../../design_system/constants/sizes.dart';
import '../../../design_system/constants/colors.dart';
import '../../../design_system/kit_shared/kit_staggered_entrance.dart';
import '../../../design_system/kit_shared/kit_bounce_scaler.dart';

/// 设置页: 个性化专页 (v3.0 - Logic Integration)
/// 遵循 SECONDARY_PAGE_SPEC 与 CARD_PROTOCOL。
class PersonalizationPage extends StatelessWidget {
  final Color themeColor;

  const PersonalizationPage({super.key, this.themeColor = Colors.purpleAccent});

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
          _SettingsCard(
            index: 1,
            title: "皮肤系统",
            icon: Icons.palette_outlined,
            child: SkinSystemAssembly(themeColor: themeColor),
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

/// SkinSystemAssembly: 包含复杂的皮肤切换逻辑。
class SkinSystemAssembly extends StatelessWidget {
  final Color themeColor;

  const SkinSystemAssembly({super.key, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();

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
            _buildIndependentSwitch(gameProvider),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // 2. 根据模式显示不同内容 (采用 渐隐 + 变高度 -> 浮现 策略)
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600), // 总时长增加，支持两个阶段
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  // 旧内容以 Positioned 包裹，使其不占用空间，从而让 AnimatedSize 立即获取新内容高度并联动
                  ...previousChildren.map(
                    (e) => Positioned(top: 0, left: 0, right: 0, child: e),
                  ),
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              // 通过 Interval 实现：前 300ms 旧的消失，后 300ms 新的出现
              // 1.0 -> 0.5 (Outgoing) / 0.5 -> 1.0 (Incoming)
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
                    key: const ValueKey('global_skin_config'),
                  )
                : _buildIndependentSection(
                    context,
                    gameProvider,
                    key: const ValueKey('independent_skin_config'),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndependentSwitch(GameProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: UiColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            label: "全局",
            isSelected: !provider.isIndependentSkin,
            onTap: () => provider.setIndependentSkin(false),
          ),
          _buildModeButton(
            label: "独立",
            isSelected: provider.isIndependentSkin,
            onTap: () => provider.setIndependentSkin(true),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return KitBounceScaler(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : UiColors.grey500,
          ),
        ),
      ),
    );
  }

  // --- 全局配置区 ---
  Widget _buildGlobalSection(
    BuildContext context,
    GameProvider provider, {
    Key? key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubTitle("当前全局皮肤"),
        const SizedBox(height: 8),
        _buildSkinSelector(
          context: context,
          options: ['default', 'maimai_dx', 'chunithm'],
          labels: ['默认星空', '舞萌 DX', '中二节奏'],
          current: provider.globalSkin,
          onSelect: provider.setGlobalSkin,
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
    GameProvider provider, {
    Key? key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubTitle("舞萌 DX 独立配置"),
        const SizedBox(height: 8),
        _buildSkinSelector(
          context: context,
          options: ['maimai_dx', 'default'],
          labels: ['标准版', '星空版'],
          current: provider.maimaiSkin,
          onSelect: provider.setMaimaiSkin,
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
        _buildSkinSelector(
          context: context,
          options: ['chunithm', 'default'],
          labels: ['标准版', '星空版'],
          current: provider.chunithmSkin,
          onSelect: provider.setChunithmSkin,
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

  Widget _buildSkinSelector({
    required BuildContext context,
    required List<String> options,
    required List<String> labels,
    required String current,
    required Function(String) onSelect,
  }) {
    final currentLabel = labels[options.indexOf(current)];

    return Builder(
      builder: (btnCtx) {
        return KitBounceScaler(
          onTap: () async {
            final result = await showMenu<String>(
              context: context,
              position: _getMenuPosition(btnCtx),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white.withValues(alpha: 0.98),
              items: List.generate(options.length, (i) {
                final isSelected = current == options[i];
                return PopupMenuItem<String>(
                  value: options[i],
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: isSelected ? themeColor : UiColors.grey400,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? themeColor : UiColors.grey700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );

            if (result != null) {
              onSelect(result);
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
                Icon(
                  Icons.palette_outlined,
                  size: 18,
                  color: themeColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "皮肤样式：$currentLabel",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: UiColors.grey700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.unfold_more,
                  size: 18,
                  color: UiColors.grey400,
                ),
              ],
            ),
          ),
        );
      },
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
