import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import '../../../../logic/mai_music_data/data_formats/mai_song_row.dart';
import '../tables/mai_songs_table.dart';
import '../app_database.dart';

part 'mai_music_dao.g.dart';

@lazySingleton
@DriftAccessor(tables: [MaiMusicTable, MaiUtageTable])
class MaiMusicDao extends DatabaseAccessor<AppDatabase>
    with _$MaiMusicDaoMixin {
  MaiMusicDao(AppDatabase db) : super(db);

  /// 批量插入曲目
  /// 根据 genre 自动分流到 mai_music_data 或 mai_utage_data 表
  Future<void> batchInsert(List<MaiSongRow> rows) async {
    await batch((batch) {
      for (final row in rows) {
        if (row.genre == '宴会场') {
          batch.insert(
            maiUtageTable,
            MaiUtageTableCompanion.insert(
              id: Value(row.id),
              title: row.title,
              artist: row.artist,
              bpm: row.bpm,
              type: row.type,
              versionText: row.versionText,
              versionId: row.versionId,
              isBuddy: Value(row.isBuddy),
              chartsJson: row.chartsJson,
            ),
            mode: InsertMode.insertOrReplace,
          );
        } else {
          batch.insert(
            maiMusicTable,
            MaiMusicTableCompanion.insert(
              id: Value(row.id),
              title: row.title,
              artist: row.artist,
              bpm: row.bpm,
              type: row.type,
              genre: row.genre,
              versionText: row.versionText,
              versionId: row.versionId,
              chartsJson: row.chartsJson,
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }

  /// 监听所有歌曲流 (示例简单的标题过滤流)
  Stream<List<MaiMusicTableData>> watchSongs({String? query}) {
    final search = query?.trim().toLowerCase() ?? '';
    if (search.isEmpty) {
      return (select(
        maiMusicTable,
      )..orderBy([(t) => OrderingTerm(expression: t.id)])).watch();
    }
    return (select(maiMusicTable)
          ..where((t) => t.title.contains(search))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .watch();
  }

  /// 监听宴会场流
  Stream<List<MaiUtageTableData>> watchUtageSongs({String? query}) {
    final search = query?.trim().toLowerCase() ?? '';
    if (search.isEmpty) {
      return (select(
        maiUtageTable,
      )..orderBy([(t) => OrderingTerm(expression: t.id)])).watch();
    }
    return (select(maiUtageTable)
          ..where((t) => t.title.contains(search))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .watch();
  }

  /// 统计曲目数量
  Future<int> countSongs() async {
    final countExp = maiMusicTable.id.count();
    final query = selectOnly(maiMusicTable)..addColumns([countExp]);
    return (await query.map((row) => row.read(countExp)).getSingle()) ?? 0;
  }
}
