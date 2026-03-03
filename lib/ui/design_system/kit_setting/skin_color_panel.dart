import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../application/shared/game_provider.dart';
import '../constants/colors.dart';
import '../constants/assets.dart';
import '../theme/core/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 调色目标键（3通道：基础色 / 亮色 / 文字色）
// ─────────────────────────────────────────────────────────────────────────────

class _ColorTarget {
  final String key;
  final String label;
  const _ColorTarget(this.key, this.label);
}

const _kColorTargets = [
  _ColorTarget('medium', '基础色'),
  _ColorTarget('light', '亮色'),
  _ColorTarget('dark', '文字色'),
];

// ─────────────────────────────────────────────────────────────────────────────
// 防抖工具
// ─────────────────────────────────────────────────────────────────────────────

class _Debouncer {
  static const _delay = Duration(milliseconds: 500);
  Timer? _timer;
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(_delay, action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SkinColorPanel：调色面板主体
//
// [ARCH_LEAK §1] 已迁移至 kit_setting 层。
// 对外契约：skin / skinId / onAutoClose 三项回调，禁止向上反依赖业务层。
// ─────────────────────────────────────────────────────────────────────────────

class SkinColorPanel extends StatefulWidget {
  final AppTheme skin;
  final String skinId;
  final VoidCallback onAutoClose;

  const SkinColorPanel({
    super.key,
    required this.skin,
    required this.skinId,
    required this.onAutoClose,
  });

  @override
  State<SkinColorPanel> createState() => _SkinColorPanelState();
}

class _SkinColorPanelState extends State<SkinColorPanel> {
  static const _autoCloseDelay = Duration(seconds: 20);

  String _activeKey = 'medium';
  double _hue = 0;
  double _saturation = 0;
  double _lightness = 0;
  final _hexController = TextEditingController();
  bool _hexFocused = false;
  final _debouncer = _Debouncer();
  Timer? _idleTimer;
  late Map<String, Color> _localColors;

  @override
  void initState() {
    super.initState();
    _resetIdleTimer();
    _initLocalColors();
    _syncFromTarget(_activeKey);
  }

  @override
  void didUpdateWidget(SkinColorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skinId != widget.skinId) {
      _initLocalColors();
      _syncFromTarget(_activeKey);
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _debouncer.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _initLocalColors() {
    final gp = context.read<GameProvider>();
    final resolved = gp.resolvedTheme(widget.skin);
    _localColors = {
      'medium': resolved.medium,
      'light': resolved.light,
      'dark': resolved.dark,
    };
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_autoCloseDelay, () => widget.onAutoClose());
  }

  void _onInteract() => _resetIdleTimer();

  void _syncFromTarget(String key) {
    final color = _localColors[key] ?? widget.skin.medium;
    final hsl = HSLColor.fromColor(color);
    setState(() {
      _hue = hsl.hue;
      _saturation = hsl.saturation;
      _lightness = hsl.lightness;
      _hexController.text = _colorToHex(color);
    });
  }

  Color get _currentColor =>
      HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();

  void _onHslChanged({double? h, double? s, double? l}) {
    _onInteract();
    setState(() {
      if (h != null) _hue = h;
      if (s != null) _saturation = s;
      if (l != null) _lightness = l;
      _localColors[_activeKey] = _currentColor;
      if (!_hexFocused) _hexController.text = _colorToHex(_currentColor);
    });
    _scheduleDiskWrite();
  }

  void _onHexSubmit(String hex) {
    _onInteract();
    final color = _hexToColor(hex);
    if (color == null) return;
    final hsl = HSLColor.fromColor(color);
    setState(() {
      _hue = hsl.hue;
      _saturation = hsl.saturation;
      _lightness = hsl.lightness;
      _localColors[_activeKey] = color;
    });
    _scheduleDiskWrite();
  }

  void _onTargetSelect(String key) {
    _onInteract();
    setState(() => _activeKey = key);
    _syncFromTarget(key);
  }

  void _onResetSkin() {
    _onInteract();
    final gp = context.read<GameProvider>();
    gp.setThemePreferences(gp.themePrefs.resetSkin(widget.skinId));
    setState(() {
      _localColors = {
        'medium': widget.skin.medium,
        'light': widget.skin.light,
        'dark': widget.skin.dark,
      };
    });
    _syncFromTarget(_activeKey);
  }

  void _scheduleDiskWrite() {
    _debouncer.run(() {
      if (!mounted) return;
      final gp = context.read<GameProvider>();
      var prefs = gp.themePrefs;
      for (final entry in _localColors.entries) {
        prefs = prefs.withColor(widget.skinId, entry.key, entry.value);
      }
      gp.setThemePreferences(prefs);
    });
  }

  static String _colorToHex(Color c) =>
      c.toARGB32().toRadixString(16).substring(2).toUpperCase();

  static Color? _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '').trim();
    if (clean.length != 6) return null;
    final v = int.tryParse('FF$clean', radix: 16);
    return v != null ? Color(v) : null;
  }

  @override
  Widget build(BuildContext context) {
    final hasCustom = context.watch<GameProvider>().themePrefs.hasCustomization(
      widget.skinId,
    );

    return GestureDetector(
      onTapDown: (_) => _onInteract(),
      behavior: HitTestBehavior.translucent,
      child: Padding(
        // [ANIMATION_FAULT §2] 统一使用 sizes.dart 规范间距
        padding: const EdgeInsets.only(top: 4, bottom: 16, left: 4, right: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 主操作区（左预览 + 右 HSL）
            // [HIGH_FI_SNAPSHOT §4] 整体行高配合加宽后的预览区
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MiniPreview(
                    skin: widget.skin,
                    localColors: Map.unmodifiable(_localColors),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HslControl(
                      hue: _hue,
                      saturation: _saturation,
                      lightness: _lightness,
                      hexController: _hexController,
                      activeColor: _currentColor,
                      hasCustom: hasCustom,
                      accentColor: _localColors['medium'] ?? widget.skin.medium,
                      onHslChanged: _onHslChanged,
                      onHexSubmit: _onHexSubmit,
                      onHexFocusChange: (f) => setState(() => _hexFocused = f),
                      onInteract: _onInteract,
                      onReset: _onResetSkin,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── 底部：圆角矩形游标选择器（3个）
            _ColorTargetRow(
              targets: _kColorTargets,
              localColors: Map.unmodifiable(_localColors),
              activeKey: _activeKey,
              onSelect: _onTargetSelect,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 左侧：高保真微缩页面快照预览
//
// [HIGH_FI_SNAPSHOT §4]
// - 绝对孤立封闭堆栈：禁止 import 或挂载任何业务 DOM
// - 宽度从 88 → 132（扩张 50%）
// - 底层 skin.buildBackground 由渐变模拟 → 叠加真实 BackdropFilter 毛玻璃
// - 右上角 Gear + Menu 图标（medium 着色）
// - 居中 LOGO + 两颗指示点 + light 半透副文本
// - 悬底大体积白色卡片（medium 按钮 + dark 文字）
// ─────────────────────────────────────────────────────────────────────────────

class _MiniPreview extends StatelessWidget {
  final AppTheme skin;
  final Map<String, Color> localColors;

  const _MiniPreview({required this.skin, required this.localColors});

  String? get _logoAsset {
    try {
      switch (skin.themeId) {
        case 'mai_circle':
          return AppAssets.logoMaimai;
        case 'chu_verse':
          return AppAssets.logoChunithm;
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final medium = localColors['medium'] ?? Colors.grey;
    final light = localColors['light'] ?? Colors.grey.shade300;
    final dark = localColors['dark'] ?? Colors.grey.shade700;
    final logoAsset = _logoAsset;

    // [HIGH_FI_SNAPSHOT] 宽度扩张 50%：88 → 132
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── 底层：skin.buildBackground 用渐变仿制（孤立堆栈规范）
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(light, medium, 0.3)!,
                          Color.lerp(medium, dark, 0.6)!,
                        ],
                      ),
                    ),
                  ),

                  // ── 玻璃层：真实 BackdropFilter + 浅白蒙版
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),

                  // ── 内容
                  Padding(
                    padding: const EdgeInsets.all(9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── 顶部：Logo 区 + 右侧 Header 按钮
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo + 副文字 + 指示点
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (logoAsset != null)
                                    Image.asset(
                                      logoAsset,
                                      height: 22,
                                      fit: BoxFit.fitHeight,
                                    )
                                  else
                                    Container(
                                      height: 22,
                                      width: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  // light 半透副文本
                                  Container(
                                    width: 38,
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      color: light.withValues(alpha: 0.75),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  // 两颗轮播指示点
                                  Row(
                                    children: [
                                      _Dot(color: medium, active: true),
                                      const SizedBox(width: 3),
                                      _Dot(
                                        color: medium.withValues(alpha: 0.3),
                                        active: false,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Gear + Menu（medium 着色）
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  size: 11,
                                  color: medium,
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.menu_rounded,
                                  size: 11,
                                  color: medium,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Spacer(),

                        // ── 悬底：大体积白色卡片
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.93),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // dark 标识文字
                              Text(
                                '示范文字',
                                style: TextStyle(
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w700,
                                  color: dark,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 5),
                              // medium 实心圆角按钮
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: medium,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '示范文字',
                                  style: TextStyle(
                                    fontSize: 5.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            skin.themeTitle,
            style: const TextStyle(
              fontSize: 10,
              color: UiColors.grey500,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// 轮播指示点
class _Dot extends StatelessWidget {
  final Color color;
  final bool active;
  const _Dot({required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 10 : 4,
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 右侧：HSL 滑轨控制中心（含 HEX + 恢复默认同行）
// ─────────────────────────────────────────────────────────────────────────────

class _HslControl extends StatelessWidget {
  final double hue;
  final double saturation;
  final double lightness;
  final TextEditingController hexController;
  final Color activeColor;
  final bool hasCustom;
  final Color accentColor;
  final void Function({double? h, double? s, double? l}) onHslChanged;
  final void Function(String) onHexSubmit;
  final void Function(bool focused) onHexFocusChange;
  final VoidCallback onInteract;
  final VoidCallback onReset;

  const _HslControl({
    required this.hue,
    required this.saturation,
    required this.lightness,
    required this.hexController,
    required this.activeColor,
    required this.hasCustom,
    required this.accentColor,
    required this.onHslChanged,
    required this.onHexSubmit,
    required this.onHexFocusChange,
    required this.onInteract,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // H 轨道（完整连续彩虹）
        _HslTrack(
          label: 'H',
          value: hue,
          min: 0,
          max: 360,
          trackGradient: const LinearGradient(
            colors: [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ],
          ),
          thumbColor: activeColor,
          onChanged: (v) {
            onInteract();
            onHslChanged(h: v);
          },
        ),
        // S 轨道（受当前 H/L 影响的饱和度渐变）
        _HslTrack(
          label: 'S',
          value: saturation,
          min: 0,
          max: 1,
          trackGradient: LinearGradient(
            colors: [
              HSLColor.fromAHSL(
                1,
                hue,
                0,
                lightness.clamp(0.05, 0.95),
              ).toColor(),
              HSLColor.fromAHSL(
                1,
                hue,
                1,
                lightness.clamp(0.05, 0.95),
              ).toColor(),
            ],
          ),
          thumbColor: activeColor,
          onChanged: (v) {
            onInteract();
            onHslChanged(s: v);
          },
        ),
        // L 轨道（受当前 H/S 影响的亮度渐变）
        _HslTrack(
          label: 'L',
          value: lightness,
          min: 0,
          max: 1,
          trackGradient: LinearGradient(
            colors: [
              const Color(0xFF000000),
              HSLColor.fromAHSL(
                1,
                hue,
                saturation.clamp(0.0, 1.0),
                0.5,
              ).toColor(),
              const Color(0xFFFFFFFF),
            ],
          ),
          thumbColor: activeColor,
          onChanged: (v) {
            onInteract();
            onHslChanged(l: v);
          },
        ),
        // HEX 输入框 + 恢复默认（同行）
        _HexInputRow(
          controller: hexController,
          activeColor: activeColor,
          hasCustom: hasCustom,
          accentColor: accentColor,
          onSubmit: onHexSubmit,
          onFocusChange: onHexFocusChange,
          onInteract: onInteract,
          onReset: onReset,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HslTrack extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final LinearGradient trackGradient;
  final Color thumbColor;
  final void Function(double) onChanged;

  const _HslTrack({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.trackGradient,
    required this.thumbColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: UiColors.grey500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              trackShape: _GradientTrackShape(gradient: trackGradient),
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: thumbColor,
              overlayColor: thumbColor.withValues(alpha: 0.18),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEX 输入框 + 恢复默认按钮（同行）
// ─────────────────────────────────────────────────────────────────────────────

class _HexInputRow extends StatelessWidget {
  final TextEditingController controller;
  final Color activeColor;
  final bool hasCustom;
  final Color accentColor;
  final void Function(String) onSubmit;
  final void Function(bool) onFocusChange;
  final VoidCallback onInteract;
  final VoidCallback onReset;

  const _HexInputRow({
    required this.controller,
    required this.activeColor,
    required this.hasCustom,
    required this.accentColor,
    required this.onSubmit,
    required this.onFocusChange,
    required this.onInteract,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 当前色预览块
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: activeColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: UiColors.grey200, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        // HEX 输入框
        Expanded(
          child: Focus(
            onFocusChange: (f) {
              onFocusChange(f);
              if (!f) onSubmit(controller.text);
            },
            child: TextField(
              controller: controller,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: UiColors.grey800,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                prefix: const Text(
                  '#',
                  style: TextStyle(
                    fontSize: 12,
                    color: UiColors.grey400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: UiColors.grey200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: activeColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: UiColors.grey200),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (v) => onInteract(),
              onSubmitted: onSubmit,
              textCapitalization: TextCapitalization.characters,
            ),
          ),
        ),
        const SizedBox(width: 6),
        // 恢复默认（inline，紧靠 HEX 框右侧）
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: hasCustom ? 1.0 : 0.35,
          child: GestureDetector(
            onTap: hasCustom ? onReset : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restart_alt_rounded,
                    size: 12,
                    color: accentColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '默认',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 底部：圆角矩形游标选择行（3等宽，内嵌文字，无外部标签）
// ─────────────────────────────────────────────────────────────────────────────

class _ColorTargetRow extends StatelessWidget {
  final List<_ColorTarget> targets;
  final Map<String, Color> localColors;
  final String activeKey;
  final void Function(String) onSelect;

  const _ColorTargetRow({
    required this.targets,
    required this.localColors,
    required this.activeKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: targets.map((t) {
        final color = localColors[t.key] ?? Colors.grey;
        final isActive = activeKey == t.key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _ColorRect(
              color: color,
              label: t.label,
              isActive: isActive,
              onTap: () => onSelect(t.key),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// 圆角矩形色彩游标
class _ColorRect extends StatelessWidget {
  final Color color;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ColorRect({
    required this.color,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  static Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.4 ? const Color(0xFF333333) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.all(isActive ? 3.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isActive ? 0.45 : 0.2),
                blurRadius: isActive ? 8 : 3,
                spreadRadius: isActive ? 1 : 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _contrastColor(color),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 自定义渐变轨道形状
//
// [UX_RENDER §3] 修复底背透明穿透问题：
// 在绘制渐变前先用极浅的白色填充整条轨道，确保无论系统主题透明度如何
// 渐变色始终完整可见。
// ─────────────────────────────────────────────────────────────────────────────

class _GradientTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  final LinearGradient gradient;

  const _GradientTrackShape({required this.gradient});

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );

    // [UX_RENDER] 先填底色（不透明白）防止透明穿底
    final basePaint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.fill;
    context.canvas.drawRRect(rrect, basePaint);

    // 再叠渐变
    final gradientPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    context.canvas.drawRRect(rrect, gradientPaint);
  }
}
