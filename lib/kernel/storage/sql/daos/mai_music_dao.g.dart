// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mai_music_dao.dart';

// ignore_for_file: type=lint
mixin _$MaiMusicDaoMixin on DatabaseAccessor<AppDatabase> {
  $MaiMusicTableTable get maiMusicTable => attachedDatabase.maiMusicTable;
  $MaiUtageTableTable get maiUtageTable => attachedDatabase.maiUtageTable;
  MaiMusicDaoManager get managers => MaiMusicDaoManager(this);
}

class MaiMusicDaoManager {
  final _$MaiMusicDaoMixin _db;
  MaiMusicDaoManager(this._db);
  $$MaiMusicTableTableTableManager get maiMusicTable =>
      $$MaiMusicTableTableTableManager(_db.attachedDatabase, _db.maiMusicTable);
  $$MaiUtageTableTableTableManager get maiUtageTable =>
      $$MaiUtageTableTableTableManager(_db.attachedDatabase, _db.maiUtageTable);
}
