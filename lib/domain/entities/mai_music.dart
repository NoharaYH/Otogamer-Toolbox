/// Maimai Music 领域实体（Xray 格式）。
/// 普通曲与宴谱在 UI 统一用 MaiMusic；basicInfo.isUtage 区分来源。
class MaiMusic {
  final MaiBasicInfo basicInfo;
  final List<MaiChart> charts;
  final MaiUtageInfo? utageInfo;
  final List<MaiUtageChart> utageCharts;

  MaiMusic({
    required this.basicInfo,
    this.charts = const [],
    this.utageInfo,
    this.utageCharts = const [],
  });
}

class MaiBasicInfo {
  final int id;
  final String title;
  final String artist;
  final int bpm;
  final String type;
  final String genre;
  final MaiVersionInfo version;
  final bool isUtage;

  MaiBasicInfo({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.type,
    required this.genre,
    required this.version,
    this.isUtage = false,
  });
}

class MaiVersionInfo {
  final String text;
  final int id;

  MaiVersionInfo({required this.text, required this.id});
}

class MaiChart {
  final int difficulty;
  final String level;
  final String levelLabel;
  final double constant;
  final String designer;
  final MaiNotes notes;

  MaiChart({
    required this.difficulty,
    required this.level,
    required this.levelLabel,
    required this.constant,
    required this.designer,
    required this.notes,
  });
}

class MaiNotes {
  final int total;
  final int tap;
  final int hold;
  final int slide;
  final int touch;
  final int breakNote;

  MaiNotes({
    required this.total,
    required this.tap,
    required this.hold,
    required this.slide,
    required this.touch,
    required this.breakNote,
  });
}

class MaiUtageInfo {
  final String level;
  final String type;
  final String commit;
  final String skipCondition;
  final List<int> playerCount;

  MaiUtageInfo({
    required this.level,
    required this.type,
    required this.commit,
    required this.skipCondition,
    required this.playerCount,
  });
}

class MaiUtageChart {
  final String? sides;
  final MaiNotes notes;

  MaiUtageChart({required this.sides, required this.notes});
}
