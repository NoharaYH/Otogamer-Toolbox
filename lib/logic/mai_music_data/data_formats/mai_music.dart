/// Maimai Music Data Model (Xray Format)
class MaiMusic {
  final MaiBasicInfo basicInfo;
  final List<MaiChart> charts;

  MaiMusic({required this.basicInfo, required this.charts});

  factory MaiMusic.fromJson(Map<String, dynamic> json) {
    return MaiMusic(
      basicInfo: MaiBasicInfo.fromJson(json['basic_info']),
      charts: (json['charts'] as List)
          .map((i) => MaiChart.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'basic_info': basicInfo.toJson(),
    'charts': charts.map((i) => i.toJson()).toList(),
  };
}

class MaiBasicInfo {
  final int id;
  final String title;
  final String artist;
  final int bpm;
  final String type; // SD or DX
  final String genre;
  final MaiVersionInfo version;

  MaiBasicInfo({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.type,
    required this.genre,
    required this.version,
  });

  factory MaiBasicInfo.fromJson(Map<String, dynamic> json) {
    return MaiBasicInfo(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      bpm: json['bpm'],
      type: json['type'] ?? '',
      genre: json['genre'],
      version: MaiVersionInfo.fromJson(json['version']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'bpm': bpm,
    'type': type,
    'genre': genre,
    'version': version.toJson(),
  };
}

class MaiVersionInfo {
  final String text;
  final int id;

  MaiVersionInfo({required this.text, required this.id});

  factory MaiVersionInfo.fromJson(Map<String, dynamic> json) {
    return MaiVersionInfo(text: json['text'], id: json['id']);
  }

  Map<String, dynamic> toJson() => {'text': text, 'id': id};
}

class MaiChart {
  final int difficulty; // 0-4
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

  factory MaiChart.fromJson(Map<String, dynamic> json) {
    return MaiChart(
      difficulty: json['difficulty'],
      level: json['level'],
      levelLabel: json['level_label'],
      constant: json['constant'].toDouble(),
      designer: json['designer'],
      notes: MaiNotes.fromJson(json['notes']),
    );
  }

  Map<String, dynamic> toJson() => {
    'difficulty': difficulty,
    'level': level,
    'level_label': levelLabel,
    'constant': constant,
    'designer': designer,
    'notes': notes.toJson(),
  };
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

  factory MaiNotes.fromJson(Map<String, dynamic> json) {
    return MaiNotes(
      total: json['total'],
      tap: json['tap'],
      hold: json['hold'],
      slide: json['slide'],
      touch: json['touch'],
      breakNote: json['break'],
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'tap': tap,
    'hold': hold,
    'slide': slide,
    'touch': touch,
    'break': breakNote,
  };
}
