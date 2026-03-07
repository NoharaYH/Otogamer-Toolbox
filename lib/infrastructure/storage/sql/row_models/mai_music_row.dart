/// 普通曲持久化行（仅写入 mai_music_data），不暴露给 domain 层。
class MaiMusicRow {
  final int id;
  final String title;
  final String artist;
  final int bpm;
  final String type;
  final String genre;
  final String versionText;
  final int versionId;
  final String chartsJson;

  const MaiMusicRow({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.type,
    required this.genre,
    required this.versionText,
    required this.versionId,
    required this.chartsJson,
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
      };
}
