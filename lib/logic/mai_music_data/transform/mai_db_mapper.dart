import 'dart:convert';
import '../../../kernel/storage/sql/app_database.dart';
import '../data_formats/mai_music.dart';

class MaiDbMapper {
  static MaiMusic fromTable(MaiMusicTableData table) {
    return MaiMusic(
      basicInfo: MaiBasicInfo(
        id: table.id,
        title: table.title,
        artist: table.artist,
        bpm: table.bpm,
        type: table.type,
        genre: table.genre,
        version: MaiVersionInfo(text: table.versionText, id: table.versionId),
      ),
      charts: _parseChartsJson(table.chartsJson),
    );
  }

  static MaiMusic fromUtageTable(MaiUtageTableData table) {
    return MaiMusic(
      basicInfo: MaiBasicInfo(
        id: table.id,
        title: table.title,
        artist: table.artist,
        bpm: table.bpm,
        type: table.type,
        genre: '宴会场',
        version: MaiVersionInfo(text: table.versionText, id: table.versionId),
      ),
      charts: _parseChartsJson(table.chartsJson),
    );
  }

  static List<MaiChart> _parseChartsJson(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((item) {
      return MaiChart(
        difficulty: item['difficulty'],
        level: item['level'],
        levelLabel: item['label'],
        constant: (item['constant'] as num).toDouble(),
        designer: item['designer'],
        notes: MaiNotes(
          total: item['total'],
          tap: item['tap'],
          hold: item['hold'],
          slide: item['slide'],
          touch: item['touch'],
          breakNote: item['break'],
        ),
      );
    }).toList();
  }
}
