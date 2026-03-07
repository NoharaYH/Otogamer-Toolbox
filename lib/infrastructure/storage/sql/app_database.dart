import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/mai_music_dao.dart';
import 'tables/mai_songs_table.dart';

part 'app_database.g.dart';

@lazySingleton
@DriftDatabase(tables: [MaiMusicTable, MaiUtageTable], daos: [MaiMusicDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTest(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          await customStatement('DROP TABLE IF EXISTS mai_utage_data');
          await customStatement('DROP TABLE IF EXISTS mai_music_data');
          await m.createAll();
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'otokit_vault.sqlite'));
      return NativeDatabase(file);
    });
  }
}
