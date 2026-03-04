import 'dart:convert';

/// SQLite 持久化单元 —— 扁平化行结构
///
/// 将合并后的歌曲数据压缩成可以逐行 batch insert 的形式：
/// - 主元信息字段可以直接映射为数据库列。
/// - 多难度谱面集合序列化为 JSON 字符串存入 `chartsJson` 列，
///   规避多表 JOIN 的查询损耗（OTOKiT 无复杂多难度独立查询需求）。
class MaiSongRow {
  final int id;
  final String title;
  final String artist;
  final int bpm;
  final String type; // SD or DX
  final String genre;
  final String versionText; // 版本名称文字 (如 "舞萌DX 2024")
  final int versionId; // 版本数字 ID (来自落雪，如 24000)
  final String chartsJson; // List<MaiChartRow> 的 JSON 序列化字符串
  // 宴曲专属：是否为双人协演谱（含 2P 谱面）。普通曲恒为 false
  final bool isBuddy;

  const MaiSongRow({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.type,
    required this.genre,
    required this.versionText,
    required this.versionId,
    required this.chartsJson,
    this.isBuddy = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artist': artist,
    'bpm': bpm,
    'type': type,
    'genre': genre,
    'version_text': versionText,
    'version_id': versionId,
    'charts_json': chartsJson,
    'is_buddy': isBuddy ? 1 : 0, // SQLite 无原生 bool，用整型 0/1 表示
  };
}

/// 谱面数据紧凑型单元（嵌入 chartsJson 内）
class MaiChartRow {
  final int difficulty; // 0=Basic 1=Adv 2=Exp 3=Mas 4=ReMas / 0=Utage 1=Utage2P
  final String levelLabel; // e.g. 'Basic', 'Utage', 'Utage 2P'
  final String level;
  final double constant;
  final String designer;
  final int notesTap;
  final int notesHold;
  final int notesSlide;
  final int notesTouch;
  final int notesBreak;
  final int notesTotal;
  // 宴会场语义标记：为 true 时表示该谱面小节属于宴曲，而非普通难度
  final bool isUtage;

  const MaiChartRow({
    required this.difficulty,
    required this.levelLabel,
    required this.level,
    required this.constant,
    required this.designer,
    required this.notesTap,
    required this.notesHold,
    required this.notesSlide,
    required this.notesTouch,
    required this.notesBreak,
    required this.notesTotal,
    this.isUtage = false,
  });

  Map<String, dynamic> toMap() => {
    'difficulty': difficulty,
    'label': levelLabel,
    'level': level,
    'constant': constant,
    'designer': designer,
    'tap': notesTap,
    'hold': notesHold,
    'slide': notesSlide,
    'touch': notesTouch,
    'break': notesBreak,
    'total': notesTotal,
    'is_utage': isUtage,
  };
}

/// 将 List<MaiChartRow> 序列化为存入 SQLite 的 JSON 字符串
String encodeCharts(List<MaiChartRow> charts) {
  return jsonEncode(charts.map((c) => c.toMap()).toList());
}
