/// 宴谱持久化行（仅写入 mai_utage_data），不暴露给 domain 层。
class MaiUtageRow {
  final int id;
  final String title;
  final String artist;
  final int bpm;
  final String type;
  final String versionText;
  final int versionId;
  final String utageInfoJson;
  final String utageChartsJson;

  const MaiUtageRow({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.type,
    required this.versionText,
    required this.versionId,
    required this.utageInfoJson,
    required this.utageChartsJson,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'bpm': bpm,
        'type': type,
        'version_text': versionText,
        'version_id': versionId,
        'utage_info_json': utageInfoJson,
        'utage_charts_json': utageChartsJson,
      };
}
