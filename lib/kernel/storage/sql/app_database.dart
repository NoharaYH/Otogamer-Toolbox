import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:injectable/injectable.dart';
import 'tables/mai_songs_table.dart';
import 'daos/mai_music_dao.dart';

part 'app_database.g.dart';

@lazySingleton
@DriftDatabase(tables: [MaiMusicTable, MaiUtageTable], daos: [MaiMusicDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'otokit_vault.sqlite'));
      return NativeDatabase(file);
    });
  }
}
