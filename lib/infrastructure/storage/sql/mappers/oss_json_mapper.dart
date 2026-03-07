import 'dart:convert';

import '../row_models/mai_music_row.dart';
import '../row_models/mai_utage_row.dart';

/// OSS 原始 JSON → 行模型（写路径），供 MusicLibraryRepositoryImpl 使用。
class OssJsonMapper {
  OssJsonMapper._();

  /// 将 OSS 拉取的普通曲 JSON 数组解析为 [MaiMusicRow]。
  static List<MaiMusicRow> parseNormalList(List<dynamic> jsonList) {
    return jsonList.map((item) {
      final basic = item['basic_info'] as Map<String, dynamic>;
      final version = basic['version'] as Map<String, dynamic>;
      final chartsRaw = item['charts'] as List<dynamic>? ?? [];
      final chartsJson = _encodeChartsFromOss(chartsRaw);
      return MaiMusicRow(
        id: basic['id'] as int,
        title: basic['title'] as String,
        artist: basic['artist'] as String,
        bpm: basic['bpm'] as int,
        type: basic['type'] as String,
        genre: basic['genre'] as String,
        versionText: version['text'] as String,
        versionId: version['id'] as int,
        chartsJson: chartsJson,
      );
    }).toList();
  }

  /// 将 OSS 拉取的宴谱 JSON 数组解析为 [MaiUtageRow]。
  static List<MaiUtageRow> parseUtageList(List<dynamic> jsonList) {
    return jsonList.map((item) {
      final basic = item['basic_info'] as Map<String, dynamic>;
      final version = basic['version'] as Map<String, dynamic>;
      final utageInfo = item['utage_info'] as Map<String, dynamic>? ?? {};
      final utageCharts = item['utage_charts'] as List<dynamic>? ?? [];
      return MaiUtageRow(
        id: basic['id'] as int,
        title: basic['title'] as String,
        artist: basic['artist'] as String,
        bpm: basic['bpm'] as int,
        type: basic['type'] as String,
        versionText: version['text'] as String,
        versionId: version['id'] as int,
        utageInfoJson: jsonEncode(utageInfo),
        utageChartsJson: jsonEncode(utageCharts),
      );
    }).toList();
  }

  static String _encodeChartsFromOss(List<dynamic> charts) {
    final list = charts.map((c) {
      final notes = c['notes'] as Map<String, dynamic>;
      return {
        'difficulty': c['difficulty'],
        'label': c['label'],
        'level': c['level'],
        'constant': c['constant'],
        'designer': c['designer'],
        'tap': notes['tap'],
        'hold': notes['hold'],
        'slide': notes['slide'],
        'touch': notes['touch'],
        'break': notes['break'],
        'total': notes['total'],
      };
    }).toList();
    return jsonEncode(list);
  }
}
