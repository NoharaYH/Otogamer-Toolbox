import 'dart:convert';
import 'package:flutter/material.dart';

/// 主题偏好持久化模型 (BASE_INFRA §1.1)
///
/// 存储格式（SKIN_COLOR.json 兼容单层结构）：
///   {"mai_circle": {"basic": "#FF548A"}}
///
/// 约定：
/// - 仅记录用户已手动自定义的皮肤 + 颜色键；未自定义的键不写入。
/// - 读取时对缺失键执行 Fallback，由调用方从单体皮肤基类获取默认值。
/// - 所有颜色以 6 位 HEX 字符串（含 '#'）存储，解析失败时静默跳过。
class ThemePreferencesModel {
  /// 内部存储：skinId -> {colorKey -> Color}
  /// 外部只通过方法访问，禁止直接操作内部 map。
  final Map<String, Map<String, Color>> _data;

  const ThemePreferencesModel._(this._data);

  /// 空模型（无任何自定义记录）
  static const ThemePreferencesModel empty = ThemePreferencesModel._({});

  // ── 序列化 ──────────────────────────────────────────────────

  /// 从 JSON 字符串还原模型。解析失败时返回 [empty]。
  factory ThemePreferencesModel.parse(String? raw) {
    if (raw == null || raw.isEmpty) return empty;
    try {
      final outer = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, Map<String, Color>>{};
      for (final skinEntry in outer.entries) {
        final inner = skinEntry.value as Map<String, dynamic>?;
        if (inner == null) continue;
        final colorMap = <String, Color>{};
        for (final colorEntry in inner.entries) {
          final color = _hexToColor(colorEntry.value as String?);
          if (color != null) colorMap[colorEntry.key] = color;
        }
        if (colorMap.isNotEmpty) result[skinEntry.key] = colorMap;
      }
      return ThemePreferencesModel._(result);
    } catch (_) {
      return empty;
    }
  }

  /// 序列化为 JSON 字符串写入存储。
  String serialize() {
    final outer = <String, dynamic>{};
    for (final skinEntry in _data.entries) {
      final inner = <String, String>{};
      for (final colorEntry in skinEntry.value.entries) {
        inner[colorEntry.key] = _colorToHex(colorEntry.value);
      }
      outer[skinEntry.key] = inner;
    }
    return jsonEncode(outer);
  }

  // ── 查询 ──────────────────────────────────────────────────

  /// 获取某皮肤某颜色键的自定义值；若未自定义则返回 null（由调用方 Fallback）。
  Color? get(String skinId, String colorKey) => _data[skinId]?[colorKey];

  /// 该皮肤是否有任何自定义记录。
  bool hasCustomization(String skinId) =>
      _data.containsKey(skinId) && _data[skinId]!.isNotEmpty;

  // ── 变更（返回新实例，保持不可变性）──────────────────────────

  /// 写入单个颜色键；返回包含该变更的新模型。
  ThemePreferencesModel withColor(String skinId, String colorKey, Color color) {
    final skinMap = Map<String, Color>.from(_data[skinId] ?? const {});
    skinMap[colorKey] = color;
    final next = Map<String, Map<String, Color>>.from(_data);
    next[skinId] = skinMap;
    return ThemePreferencesModel._(next);
  }

  /// 清除某皮肤的所有自定义记录；返回新模型。
  ThemePreferencesModel resetSkin(String skinId) {
    final next = Map<String, Map<String, Color>>.from(_data)..remove(skinId);
    return ThemePreferencesModel._(next);
  }

  // ── 私有工具 ──────────────────────────────────────────────

  static Color? _hexToColor(String? hex) {
    if (hex == null) return null;
    final clean = hex.replaceFirst('#', '').trim();
    if (clean.length != 6) return null;
    final value = int.tryParse('FF$clean', radix: 16);
    return value != null ? Color(value) : null;
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThemePreferencesModel && other.serialize() == serialize());

  @override
  int get hashCode => _data.hashCode;
}
