import 'dart:isolate';
import '../data_formats/mai_song_row.dart';

class MaiTransformer {
  /// 将水鱼和落雪的原始数据精炼为 SQLite 可直接批量插入的扁平行列表
  ///
  /// - 输出变更: List<MaiMusic> → List<MaiSongRow>
  ///   charts 集合压缩为 JSON 字符串写入 `chartsJson` 列，规避运行期内存大对象聚合。
  /// - 运算隔离: 整个合并过程应由调用方通过 [Isolate.run] 包裹，保证主线程零阻塞。
  static Future<List<MaiSongRow>> transform(
    List<dynamic> dfRaw,
    List<dynamic> lxRaw, {
    void Function(int current, int total)? onProgress,
  }) async {
    // 落雪数据以 id 为主键建立 O(1) 查找索引
    final Map<int, dynamic> lxMap = {
      for (var song in lxRaw) song['id'] as int: song,
    };

    final List<MaiSongRow> rows = [];
    final int totalCount = dfRaw.length;

    for (int i = 0; i < totalCount; i++) {
      final dfSong = dfRaw[i];

      // 每处理 50 首曲目，主动出让一次主线程，防止阻塞 UI 动画渲染
      if (i % 50 == 0) {
        await Future.delayed(Duration.zero);
        onProgress?.call(i, totalCount);
      }

      final int id = int.tryParse(dfSong['id'].toString()) ?? 0;
      final lxSong = lxMap[id];

      // 双源均有记录方可合并，否则跳过
      if (lxSong == null) continue;

      final List<dynamic> dfCharts = dfSong['charts'];
      final List<dynamic> dfDs = dfSong['ds'];
      final List<dynamic> dfLevels = dfSong['level'];
      final String genre = dfSong['basic_info']['genre'] ?? '';
      // 孴会场识别：宴曲的谱面不是难度分层而是玩家角色分层
      final bool isUtage = genre == '宴会场';

      // 谱面集合转换为紧凑型 MaiChartRow 序列
      final List<MaiChartRow> chartRows = [];
      for (int j = 0; j < dfCharts.length; j++) {
        final dfChart = dfCharts[j];
        final List<dynamic> notes = dfChart['notes'];

        chartRows.add(
          MaiChartRow(
            difficulty: j,
            levelLabel: isUtage
                ? (j == 0 ? 'Utage' : 'Utage 2P') // 宴曲专属标签：1P / 2P 脚色区分
                : _getDifficultyLabel(j), // 普通谱面标签
            level: dfLevels[j].toString(),
            constant: (dfDs[j] as num).toDouble(),
            designer: dfChart['charter'] ?? '-',
            notesTap: notes[0],
            notesHold: notes[1],
            notesSlide: notes[2],
            notesTouch: notes.length > 3 ? notes[3] : 0,
            notesBreak: notes.length > 4
                ? notes[4]
                : (notes.length == 4 ? notes[3] : 0),
            notesTotal: _sumNotes(notes),
            isUtage: isUtage,
          ),
        );
      }

      rows.add(
        MaiSongRow(
          id: id,
          title: dfSong['title'],
          artist: dfSong['basic_info']['artist'],
          bpm: dfSong['basic_info']['bpm'] as int,
          type: dfSong['type'] ?? '',
          genre: dfSong['basic_info']['genre'],
          versionText: dfSong['basic_info']['from'],
          versionId: lxSong['version'] as int, // 来自落雪，整型精确版本号
          chartsJson: encodeCharts(chartRows), // 谱面集合 → JSON 字符串列
          // 宴曲协演谱：isUtage 且有 2 张谱面（1P + 2P）时为 true
          isBuddy: isUtage && chartRows.length > 1,
        ),
      );
    }

    // 最后播报一次 100%
    onProgress?.call(totalCount, totalCount);

    return rows;
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
