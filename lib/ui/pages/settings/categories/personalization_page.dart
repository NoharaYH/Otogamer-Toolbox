import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../application/shared/game_provider.dart';
import '../../../../application/shared/glass_slider_preview_provider.dart';
import '../../../../shared/models/glass_overlay_prefs.dart';
import '../../../design_system/constants/sizes.dart';
import '../../../design_system/constants/colors.dart';
import '../../../design_system/theme/core/app_theme.dart';
import '../../../design_system/theme/theme_catalog.dart';
import '../../../design_system/kit_setting/setting_card.dart';
import '../../../design_system/kit_setting/animations/expansion_animator.dart';
// [ARCH_LEAK §1] 已迁移至 kit_setting 层
import '../../../design_system/kit_setting/skin_color_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 应用模式枚举
// ─────────────────────────────────────────────────────────────────────────────

enum _ThemeMode {
  global, // 全局：一个 Dropdown 控制所有游戏
  independent, // 独立：舞萌 / 中二各有独立 Dropdown
}

// ─────────────────────────────────────────────────────────────────────────────
// 个性化专页（STRUCTURAL_REVERSION §1）
// ─────────────────────────────────────────────────────────────────────────────

/// 设置页: 个性化专页
///
/// 层级逻辑：
/// - 模式选择器（全局 / 独立）
/// - 按模式渲染相应的 Dropdown + 调色面板展开槽
/// - 玻璃效果卡片：拖动滑块时由 [GlassSliderPreviewProvider] 触发整页仅保留当前滑条（类系统亮度条）
class PersonalizationPage extends StatelessWidget {
  const PersonalizationPage({super.key, Color? themeColor});

  @override
  Widget build(BuildContext context) {
    final previewProvider = context.read<GlassSliderPreviewProvider>();
    return SingleChildScrollView(
      key: const ValueKey('personalization_page_view'),
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(
        horizontal: UiSizes.getHorizontalMargin(context),
        vertical: 20,
      ),
      child: Column(
        children: [
          const SettingCard(
            index: 1,
            title: '主题皮肤',
            icon: Icons.palette_outlined,
            child: SkinSelectorAssembly(),
          ),
          const SizedBox(height: 16),
          SettingCard(
            index: 2,
            title: '主界面玻璃效果',
            icon: Icons.blur_on,
            child: GlassOverlaySettingsContent(
              isPreviewMode: false,
              activeSliderKey: null,
              onSliderDragStart: previewProvider.startDrag,
              onSliderDragEnd: previewProvider.endDrag,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 玻璃效果设置内容：不透明度 / 模糊 / 描边（含 S/L）；拖动时仅保留当前滑条供预览
// ─────────────────────────────────────────────────────────────────────────────

class GlassOverlaySettingsContent extends StatelessWidget {
  const GlassOverlaySettingsContent({
    super.key,
    required this.isPreviewMode,
    required this.activeSliderKey,
    required this.onSliderDragStart,
    required this.onSliderDragEnd,
  });

  final bool isPreviewMode;
  final String? activeSliderKey;
  final void Function(String key) onSliderDragStart;
  final VoidCallback onSliderDragEnd;

  static const String _keyOpacity = 'opacity';
  static const String _keyBlur = 'blur';

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final prefs = gp.glassOverlayPrefs;

    if (isPreviewMode && activeSliderKey != null) {
      return _buildSingleRow(context, prefs, gp, activeSliderKey!);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOpacityRow(context, prefs, gp),
        const SizedBox(height: 12),
        _buildBlurRow(context, prefs, gp),
        const SizedBox(height: 12),
        _buildStrokeSection(context, prefs, gp),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => gp.setGlassOverlayPrefs(GlassOverlayPrefs.initial),
            icon: const Icon(Icons.restore_rounded, size: 18, color: UiColors.grey600),
            label: const Text('恢复默认', style: TextStyle(fontSize: 13, color: UiColors.grey600)),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleRow(
      BuildContext context, GlassOverlayPrefs prefs, GameProvider gp, String key) {
    Widget row;
    switch (key) {
      case _keyOpacity:
        row = _buildOpacityRow(context, prefs, gp);
        break;
      case _keyBlur:
        row = _buildBlurRow(context, prefs, gp);
        break;
      default:
        return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        const SizedBox(height: 12),
        Text(
          '松开恢复',
          style: TextStyle(fontSize: 11, color: UiColors.grey500),
        ),
      ],
    );
  }

  void _applyPrefs(GameProvider gp, GlassOverlayPrefs next) {
    var applied = next;
    if (applied.effectiveOpacity == 0 && applied.effectiveBlur == 0) {
      applied = applied.copyWith(opacity: GlassOverlayPrefs.opacitySafeThreshold255);
    }
    gp.setGlassOverlayPrefs(applied);
  }

  Widget _buildOpacityRow(
      BuildContext context, GlassOverlayPrefs prefs, GameProvider gp) {
    const maxAlpha = 255.0;
    final minAlpha = prefs.blurEnabled ? 0.0 : GlassOverlayPrefs.opacitySafeThreshold255;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('不透明度', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: UiColors.grey800)),
            const SizedBox(width: 12),
            Switch(
              value: prefs.opacityEnabled,
              onChanged: (v) {
                var next = prefs.copyWith(opacityEnabled: v);
                if (v && next.opacity < minAlpha) next = next.copyWith(opacity: minAlpha);
                _applyPrefs(gp, next);
              },
            ),
          ],
        ),
        if (prefs.opacityEnabled) ...[
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: prefs.opacity.clamp(minAlpha, maxAlpha),
              min: minAlpha,
              max: maxAlpha,
              onChanged: (v) {
                var next = prefs.copyWith(opacity: v);
                if (v == 0 && next.effectiveBlur == 0) next = next.copyWith(blurEnabled: true, blurStrength: 0.1);
                gp.setGlassOverlayPrefs(next.normalized());
              },
              onChangeStart: (_) => onSliderDragStart(_keyOpacity),
              onChangeEnd: (_) => onSliderDragEnd(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBlurRow(
      BuildContext context, GlassOverlayPrefs prefs, GameProvider gp) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('模糊', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: UiColors.grey800)),
            const SizedBox(width: 12),
            Switch(
              value: prefs.blurEnabled,
              onChanged: (v) => _applyPrefs(gp, prefs.copyWith(blurEnabled: v)),
            ),
          ],
        ),
        if (prefs.blurEnabled) ...[
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: prefs.blurStrength,
              min: 0.0,
              max: 1.0,
              onChanged: (v) {
                var next = prefs.copyWith(blurStrength: v);
                if (v == 0 && next.effectiveOpacity == 0) next = next.copyWith(opacity: GlassOverlayPrefs.opacitySafeThreshold255);
                gp.setGlassOverlayPrefs(next.normalized());
              },
              onChangeStart: (_) => onSliderDragStart(_keyBlur),
              onChangeEnd: (_) => onSliderDragEnd(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStrokeSection(
      BuildContext context, GlassOverlayPrefs prefs, GameProvider gp) {
    return Row(
      children: [
        const Text('描边', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: UiColors.grey800)),
        const SizedBox(width: 12),
        Switch(
          value: prefs.strokeEnabled,
          onChanged: (v) => _applyPrefs(
            gp,
            prefs.copyWith(
              strokeEnabled: v,
              strokeSolidWhite: false,
              strokeSaturation: 0,
              strokeLightness: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 皮肤选择器主辖件
// ─────────────────────────────────────────────────────────────────────────────

/// 皮肤选择器（模式选择 → Dropdown 级联 → 调色面板槽）
class SkinSelectorAssembly extends StatefulWidget {
  const SkinSelectorAssembly({super.key});

  @override
  State<SkinSelectorAssembly> createState() => _SkinSelectorAssemblyState();
}

class _SkinSelectorAssemblyState extends State<SkinSelectorAssembly> {
  // ── 全局模式：面板是否展开
  bool _globalPanelOpen = false;

  // ── 独立模式：面板展开状态
  bool _maiPanelOpen = false;
  bool _chuPanelOpen = false;

  // ── 皮肤分类（独立模式过滤源）
  static List<AppTheme> get _maiSkins => ThemeCatalog.allThemes
      .where(
        (s) => s.themeId == 'star_trails' || s.domain == ThemeDomain.maimai,
      )
      .toList();

  static List<AppTheme> get _chuSkins => ThemeCatalog.allThemes
      .where(
        (s) => s.themeId == 'star_trails' || s.domain == ThemeDomain.chunithm,
      )
      .toList();

  // ── 20s auto-close 回调
  void _onGlobalAutoClose() {
    if (!mounted) return;
    setState(() => _globalPanelOpen = false);
  }

  void _onMaiAutoClose() {
    if (!mounted) return;
    setState(() => _maiPanelOpen = false);
  }

  void _onChuAutoClose() {
    if (!mounted) return;
    setState(() => _chuPanelOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final mode = gp.isThemeGlobal ? _ThemeMode.global : _ThemeMode.independent;

    // [ANIMATION_FAULT §2] 内容区整体用 AnimatedSize 包裹，
    // 避免全局/独立模式切换时高度突然跳变。
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 模式选择器
        _ModeSelector(
          current: mode,
          onChanged: (m) {
            gp.setThemeMode(m == _ThemeMode.global);
            setState(() {
              // 切换模式时收起所有面板
              _globalPanelOpen = false;
              _maiPanelOpen = false;
              _chuPanelOpen = false;
            });
          },
        ),

        const SizedBox(height: UiSizes.spaceS),
        const Divider(height: 1, thickness: 0.5),
        const SizedBox(height: UiSizes.spaceS),

        // ── 内容区：AnimatedSize 防抖高度过渡（消除跳闪）
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: KeyedSubtree(
            key: ValueKey(mode),
            child: mode == _ThemeMode.global
                ? _GlobalThemeSection(
                    panelOpen: _globalPanelOpen,
                    onDropdownChanged: (skinId) {
                      gp.setActiveSkin(skinId);
                      setState(() => _globalPanelOpen = false);
                    },
                    onTogglePanel: () =>
                        setState(() => _globalPanelOpen = !_globalPanelOpen),
                    onAutoClose: _onGlobalAutoClose,
                  )
                : _IndependentThemeSection(
                    maiSkinId: gp.maiSkinId,
                    chuSkinId: gp.chuSkinId,
                    maiPanelOpen: _maiPanelOpen,
                    chuPanelOpen: _chuPanelOpen,
                    onMaiChanged: (id) {
                      gp.setMaiSkin(id);
                      setState(() => _maiPanelOpen = false);
                    },
                    onChuChanged: (id) {
                      gp.setChuSkin(id);
                      setState(() => _chuPanelOpen = false);
                    },
                    onToggleMaiPanel: () =>
                        setState(() => _maiPanelOpen = !_maiPanelOpen),
                    onToggleChuPanel: () =>
                        setState(() => _chuPanelOpen = !_chuPanelOpen),
                    onMaiAutoClose: _onMaiAutoClose,
                    onChuAutoClose: _onChuAutoClose,
                    maiSkins: _maiSkins,
                    chuSkins: _chuSkins,
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 模式选择器
// ─────────────────────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  final _ThemeMode current;
  final void Function(_ThemeMode) onChanged;

  const _ModeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ModeChip(
          label: '应用于全局',
          icon: Icons.public_rounded,
          isSelected: current == _ThemeMode.global,
          onTap: () => onChanged(_ThemeMode.global),
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: '独立应用',
          icon: Icons.tune_rounded,
          isSelected: current == _ThemeMode.independent,
          onTap: () => onChanged(_ThemeMode.independent),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected
            ? UiColors.grey800.withValues(alpha: 0.08)
            : Colors.transparent,
        border: Border.all(
          color: isSelected ? UiColors.grey600 : UiColors.grey200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? UiColors.grey800 : UiColors.grey400,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? UiColors.grey800 : UiColors.grey400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 全局模式面板
// ─────────────────────────────────────────────────────────────────────────────

class _GlobalThemeSection extends StatelessWidget {
  final bool panelOpen;
  final void Function(String) onDropdownChanged;
  final VoidCallback onTogglePanel;
  final VoidCallback onAutoClose;

  const _GlobalThemeSection({
    required this.panelOpen,
    required this.onDropdownChanged,
    required this.onTogglePanel,
    required this.onAutoClose,
  });

  @override
  Widget build(BuildContext context) {
    final activeSkinId = context.watch<GameProvider>().activeSkinId;
    final activeSkin = ThemeCatalog.findThemeById(activeSkinId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown + 展开调色面板按钮
        _SkinDropdownRow(
          label: '全局皮肤',
          skins: ThemeCatalog.allThemes,
          selectedId: activeSkinId,
          panelOpen: panelOpen,
          resolvedSkin: context.watch<GameProvider>().resolvedTheme(activeSkin),
          onChanged: onDropdownChanged,
          onTogglePanel: onTogglePanel,
        ),
        // 调色面板展开槽
        ExpansionAnimator(
          isExpanded: panelOpen,
          child: SkinColorPanel(
            key: ValueKey('global_panel_$activeSkinId'),
            skin: activeSkin,
            skinId: activeSkinId,
            onAutoClose: onAutoClose,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 独立模式面板
// ─────────────────────────────────────────────────────────────────────────────

class _IndependentThemeSection extends StatelessWidget {
  final String maiSkinId;
  final String chuSkinId;
  final bool maiPanelOpen;
  final bool chuPanelOpen;
  final List<AppTheme> maiSkins;
  final List<AppTheme> chuSkins;
  final void Function(String) onMaiChanged;
  final void Function(String) onChuChanged;
  final VoidCallback onToggleMaiPanel;
  final VoidCallback onToggleChuPanel;
  final VoidCallback onMaiAutoClose;
  final VoidCallback onChuAutoClose;

  const _IndependentThemeSection({
    required this.maiSkinId,
    required this.chuSkinId,
    required this.maiPanelOpen,
    required this.chuPanelOpen,
    required this.maiSkins,
    required this.chuSkins,
    required this.onMaiChanged,
    required this.onChuChanged,
    required this.onToggleMaiPanel,
    required this.onToggleChuPanel,
    required this.onMaiAutoClose,
    required this.onChuAutoClose,
  });

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();

    final maiSkin = maiSkins.firstWhere(
      (s) => s.themeId == maiSkinId,
      orElse: () => maiSkins.first,
    );
    final chuSkin = chuSkins.firstWhere(
      (s) => s.themeId == chuSkinId,
      orElse: () => chuSkins.first,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 舞萌 DX
        _GameLabel(label: '舞萌 DX'),
        const SizedBox(height: UiSizes.spaceXXS),
        _SkinDropdownRow(
          label: '皮肤',
          skins: maiSkins,
          selectedId: maiSkinId,
          panelOpen: maiPanelOpen,
          resolvedSkin: gp.resolvedTheme(maiSkin),
          onChanged: onMaiChanged,
          onTogglePanel: onToggleMaiPanel,
        ),
        ExpansionAnimator(
          isExpanded: maiPanelOpen,
          child: SkinColorPanel(
            key: ValueKey('mai_panel_$maiSkinId'),
            skin: maiSkin,
            skinId: maiSkinId,
            onAutoClose: onMaiAutoClose,
          ),
        ),

        const SizedBox(height: UiSizes.spaceS),
        const Divider(height: 1, thickness: 0.5),
        const SizedBox(height: UiSizes.spaceS),

        // ── 中二节奏
        _GameLabel(label: '中二节奏'),
        const SizedBox(height: UiSizes.spaceXXS),
        _SkinDropdownRow(
          label: '皮肤',
          skins: chuSkins,
          selectedId: chuSkinId,
          panelOpen: chuPanelOpen,
          resolvedSkin: gp.resolvedTheme(chuSkin),
          onChanged: onChuChanged,
          onTogglePanel: onToggleChuPanel,
        ),
        ExpansionAnimator(
          isExpanded: chuPanelOpen,
          child: SkinColorPanel(
            key: ValueKey('chu_panel_$chuSkinId'),
            skin: chuSkin,
            skinId: chuSkinId,
            onAutoClose: onChuAutoClose,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 共享子组件
// ─────────────────────────────────────────────────────────────────────────────

/// 游戏分区标签
class _GameLabel extends StatelessWidget {
  final String label;
  const _GameLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: UiColors.grey500,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Dropdown 行：皮肤选择下拉 + 展开调色面板的箭头按钮
class _SkinDropdownRow extends StatelessWidget {
  final String label;
  final List<AppTheme> skins;
  final String selectedId;
  final bool panelOpen;
  final AppTheme resolvedSkin;
  final void Function(String) onChanged;
  final VoidCallback onTogglePanel;

  const _SkinDropdownRow({
    required this.label,
    required this.skins,
    required this.selectedId,
    required this.panelOpen,
    required this.resolvedSkin,
    required this.onChanged,
    required this.onTogglePanel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SkinDropdown(
            skins: skins,
            selectedId: selectedId,
            onChanged: onChanged,
          ),
        ),

        const SizedBox(width: 8),

        // 展开/收起调色面板按钮
        GestureDetector(
          onTap: onTogglePanel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: panelOpen
                  ? UiColors.grey800.withValues(alpha: 0.07)
                  : Colors.transparent,
              border: Border.all(
                color: panelOpen ? UiColors.grey400 : UiColors.grey200,
                width: 1,
              ),
            ),
            child: AnimatedRotation(
              turns: panelOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: UiColors.grey500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 皮肤 Dropdown 组件
class _SkinDropdown extends StatelessWidget {
  final List<AppTheme> skins;
  final String selectedId;
  final void Function(String) onChanged;

  const _SkinDropdown({
    required this.skins,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 安全兜底：若 selectedId 不在列表中，降级至第一项
    final safeId = skins.any((s) => s.themeId == selectedId)
        ? selectedId
        : skins.first.themeId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: UiColors.grey200),
        color: UiColors.grey100.withValues(alpha: 0.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeId,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: UiColors.grey800,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          items: skins
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s.themeId,
                  child: Text(s.themeTitle),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id != null) onChanged(id);
          },
        ),
      ),
    );
  }
}
