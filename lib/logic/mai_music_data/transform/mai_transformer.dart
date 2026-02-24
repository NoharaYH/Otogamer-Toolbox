import '../data_formats/mai_music.dart';

class MaiTransformer {
  /// 将水鱼和落雪的原始数据精炼为统一的 MaiMusic 模型列表
  static List<MaiMusic> transform(List<dynamic> dfRaw, List<dynamic> lxRaw) {
    final Map<int, dynamic> lxMap = {
      for (var song in lxRaw) song['id'] as int: song,
    };

    final List<MaiMusic> refinedList = [];

    for (var dfSong in dfRaw) {
      final int id = int.tryParse(dfSong['id'].toString()) ?? 0;
      final lxSong = lxMap[id];

      if (lxSong != null) {
        // 提取谱面
        final List<dynamic> dfCharts = dfSong['charts'];
        final List<dynamic> dfDs = dfSong['ds'];
        final List<dynamic> dfLevels = dfSong['level'];

        final List<MaiChart> charts = [];
        for (int i = 0; i < dfCharts.length; i++) {
          final dfChart = dfCharts[i];
          final List<dynamic> notesArr = dfChart['notes'];

          charts.add(
            MaiChart(
              difficulty: i,
              level: dfLevels[i].toString(),
              levelLabel: _getDifficultyLabel(i),
              constant: (dfDs[i] as num).toDouble(),
              designer: dfChart['charter'] ?? '-',
              notes: MaiNotes(
                total: _sumNotes(notesArr),
                tap: notesArr[0],
                hold: notesArr[1],
                slide: notesArr[2],
                touch: notesArr.length > 3 ? notesArr[3] : 0,
                breakNote: notesArr.length > 4
                    ? notesArr[4]
                    : (notesArr.length == 4 ? notesArr[3] : 0),
              ),
            ),
          );
        }

        refinedList.add(
          MaiMusic(
            basicInfo: MaiBasicInfo(
              id: id,
              title: dfSong['title'],
              artist: dfSong['basic_info']['artist'],
              bpm: dfSong['basic_info']['bpm'],
              type: dfSong['type'],
              genre: dfSong['basic_info']['genre'],
              version: MaiVersionInfo(
                text: dfSong['basic_info']['from'],
                id: lxSong['version'],
              ),
            ),
            charts: charts,
          ),
        );
      }
    }
    return refinedList;
  }

  static String _getDifficultyLabel(int index) {
    const labels = ['Basic', 'Advanced', 'Expert', 'Master', 'Re:Master'];
    if (index < labels.length) return labels[index];
    return 'Unknown';
  }

  static int _sumNotes(List<dynamic> notes) {
    return notes.fold(0, (sum, item) => sum + (item as int));
  }
}
