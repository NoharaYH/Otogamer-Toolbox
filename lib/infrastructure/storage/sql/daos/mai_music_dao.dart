import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../app_database.dart';
import '../row_models/mai_music_row.dart';
import '../row_models/mai_utage_row.dart';
import '../tables/mai_songs_table.dart';

part 'mai_music_dao.g.dart';

@lazySingleton
@DriftAccessor(tables: [MaiMusicTable, MaiUtageTable])
class MaiMusicDao extends DatabaseAccessor<AppDatabase> with _$MaiMusicDaoMixin {
  MaiMusicDao(super.db);

  Future<void> batchInsertNormal(List<MaiMusicRow> rows) async {
    await batch((batch) {
      for (final row in rows) {
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
    });
  }

  Future<void> batchInsertUtage(List<MaiUtageRow> rows) async {
    await batch((batch) {
      for (final row in rows) {
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
            utageInfoJson: row.utageInfoJson,
            utageChartsJson: row.utageChartsJson,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Stream<List<MaiMusicTableData>> watchSongs({String? query}) {
    final search = query?.trim().toLowerCase() ?? '';
    if (search.isEmpty) {
      return (select(maiMusicTable)
            ..orderBy([(t) => OrderingTerm(expression: t.id)]))
          .watch();
    }
    return (select(maiMusicTable)
          ..where((t) => t.title.contains(search))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .watch();
  }

  Stream<List<MaiUtageTableData>> watchUtageSongs({String? query}) {
    final search = query?.trim().toLowerCase() ?? '';
    if (search.isEmpty) {
      return (select(maiUtageTable)
            ..orderBy([(t) => OrderingTerm(expression: t.id)]))
          .watch();
    }
    return (select(maiUtageTable)
          ..where((t) => t.title.contains(search))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .watch();
  }

  Future<int> countSongs() async {
    final countExp = maiMusicTable.id.count();
    final query = selectOnly(maiMusicTable)..addColumns([countExp]);
    return (await query.map((row) => row.read(countExp)).getSingle()) ?? 0;
  }

  Future<int> countUtageSongs() async {
    final countExp = maiUtageTable.id.count();
    final query = selectOnly(maiUtageTable)..addColumns([countExp]);
    return (await query.map((row) => row.read(countExp)).getSingle()) ?? 0;
  }
}
