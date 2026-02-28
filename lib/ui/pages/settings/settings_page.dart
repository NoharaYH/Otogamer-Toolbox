import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design_system/constants/colors.dart';
import '../../design_system/constants/strings.dart';
import '../../../application/shared/navigation_provider.dart';
import '../../../application/shared/game_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final primaryColor = Theme.of(context).primaryColor;

    return Material(
      color: UiColors.transparent,
      child: Stack(
        children: [
          // 毛玻璃背景背板
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: UiColors.white.withValues(alpha: 0.8)),
            ),
          ),
          // 真正的界面层
          SafeArea(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(
                    top: 80,
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  children: [
                    const Text(
                      UiStrings.personalization,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: UiColors.grey800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(UiStrings.startupPage),
                    const SizedBox(height: 8),

                    // 启动页设置项 (三选一)
                    _buildOption(
                      context,
                      title: UiStrings.startupMai,
                      isSelected:
                          gameProvider.startupPref == StartupPagePref.mai,
                      onTap: () =>
                          gameProvider.setStartupPref(StartupPagePref.mai),
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 12),
                    _buildOption(
                      context,
                      title: UiStrings.startupChu,
                      isSelected:
                          gameProvider.startupPref == StartupPagePref.chu,
                      onTap: () =>
                          gameProvider.setStartupPref(StartupPagePref.chu),
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 12),
                    _buildOption(
                      context,
                      title: UiStrings.startupLast,
                      isSelected:
                          gameProvider.startupPref == StartupPagePref.last,
                      onTap: () =>
                          gameProvider.setStartupPref(StartupPagePref.last),
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
                // 左上角返回键
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 28,
                      color: UiColors.grey800,
                    ),
                    onPressed: () {
                      context.read<NavigationProvider>().closeSettings();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : UiColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : UiColors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? primaryColor : UiColors.grey400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryColor : UiColors.grey700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: UiColors.grey600,
        ),
      ),
    );
  }
}
