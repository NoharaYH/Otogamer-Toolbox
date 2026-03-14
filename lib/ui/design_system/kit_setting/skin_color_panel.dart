import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../application/shared/game_provider.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../theme/core/app_theme.dart';

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

  static const _activeKey = 'basic';
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
    _localColors = {'basic': resolved.basic};
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_autoCloseDelay, () => widget.onAutoClose());
  }

  void _onInteract() => _resetIdleTimer();

  void _syncFromTarget(String key) {
    final color = _localColors[key] ?? widget.skin.basic;
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

  void _onResetSkin() {
    _onInteract();
    final gp = context.read<GameProvider>();
    gp.setThemePreferences(gp.themePrefs.resetSkin(widget.skinId));
    setState(() {
      _localColors = {'basic': widget.skin.basic};
    });
    _syncFromTarget(_activeKey);
  }

  void _scheduleDiskWrite() {
    _debouncer.run(() {
      if (!mounted) return;
      final gp = context.read<GameProvider>();
      final prefs = gp.themePrefs.withColor(
        widget.skinId,
        _activeKey,
        _localColors[_activeKey] ?? widget.skin.basic,
      );
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
        padding: const EdgeInsets.only(
          top: UiSizes.atomicComponentGap,
          bottom: 0,
        ),
        child: _HslControl(
          hue: _hue,
          saturation: _saturation,
          lightness: _lightness,
          hexController: _hexController,
          activeColor: _currentColor,
          hasCustom: hasCustom,
          accentColor: _localColors[_activeKey] ?? widget.skin.basic,
          onHslChanged: _onHslChanged,
          onHexSubmit: _onHexSubmit,
          onHexFocusChange: (f) => setState(() => _hexFocused = f),
          onInteract: _onInteract,
          onReset: _onResetSkin,
        ),
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
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white,
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
