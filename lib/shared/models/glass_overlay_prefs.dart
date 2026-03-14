import 'dart:convert';

/// 玻璃层偏好持久化模型。
///
/// 存储格式：单层 JSON，与 [ThemePreferencesModel] 风格一致。
/// 仅三个开关：不透明度、模糊、描边；不透明度与模糊为硬编码值。
class GlassOverlayPrefs {
  const GlassOverlayPrefs({
    this.opacityEnabled = true,
    this.blurEnabled = false,
    this.strokeEnabled = false,
  });

  final bool opacityEnabled;
  final bool blurEnabled;
  final bool strokeEnabled;

  /// 出厂默认：仅不透明度开启，模糊和描边关闭。
  static const GlassOverlayPrefs initial = GlassOverlayPrefs();

  // ── 序列化 ──────────────────────────────────────────────────

  factory GlassOverlayPrefs.parse(String? raw) {
    if (raw == null || raw.isEmpty) return initial;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GlassOverlayPrefs(
        opacityEnabled: map['opacityEnabled'] as bool? ?? true,
        blurEnabled: map['blurEnabled'] as bool? ?? false,
        strokeEnabled: map['strokeEnabled'] as bool? ?? false,
      ).normalized();
    } catch (_) {
      return initial;
    }
  }

  String serialize() {
    return jsonEncode({
      'opacityEnabled': opacityEnabled,
      'blurEnabled': blurEnabled,
      'strokeEnabled': strokeEnabled,
    });
  }

  // ── 互斥规范化 ───────────────────────────────────────────────

  /// 关闭不透明度时，强制模糊和描边为 false。
  GlassOverlayPrefs normalized() {
    if (opacityEnabled) return this;
    return copyWith(blurEnabled: false, strokeEnabled: false);
  }

  // ── 变更 ─────────────────────────────────────────────────────

  GlassOverlayPrefs copyWith({
    bool? opacityEnabled,
    bool? blurEnabled,
    bool? strokeEnabled,
  }) {
    return GlassOverlayPrefs(
      opacityEnabled: opacityEnabled ?? this.opacityEnabled,
      blurEnabled: blurEnabled ?? this.blurEnabled,
      strokeEnabled: strokeEnabled ?? this.strokeEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GlassOverlayPrefs &&
          other.opacityEnabled == opacityEnabled &&
          other.blurEnabled == blurEnabled &&
          other.strokeEnabled == strokeEnabled);

  @override
  int get hashCode => Object.hash(opacityEnabled, blurEnabled, strokeEnabled);
}
