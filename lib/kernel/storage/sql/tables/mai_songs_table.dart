import 'package:drift/drift.dart';

@DataClassName('MaiMusicTableData')
class MaiMusicTable extends Table {
  @override
  String get tableName => 'mai_music_data';

  IntColumn get id => integer()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get artist => text()();
  IntColumn get bpm => integer()();
  TextColumn get type => text()(); // SD or DX
  TextColumn get genre => text()();
  TextColumn get versionText => text()();
  IntColumn get versionId => integer()();
  TextColumn get chartsJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MaiUtageTableData')
class MaiUtageTable extends Table {
  @override
  String get tableName => 'mai_utage_data';

  IntColumn get id => integer()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get artist => text()();
  IntColumn get bpm => integer()();
  TextColumn get type => text()();
  TextColumn get versionText => text()();
  IntColumn get versionId => integer()();
  BoolColumn get isBuddy => boolean().withDefault(const Constant(false))();
  TextColumn get chartsJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}
