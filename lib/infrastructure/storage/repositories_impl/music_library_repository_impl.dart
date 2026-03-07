import 'package:injectable/injectable.dart';

import '../../../domain/entities/mai_music.dart';
import '../../../domain/entities/sync_result.dart';
import '../../../domain/repositories/music_library_repository.dart';
import '../../network/clients/oss_api_client.dart';
import '../sql/daos/mai_music_dao.dart';
import '../sql/mappers/music_row_mapper.dart';
import '../sql/mappers/oss_json_mapper.dart';

@lazySingleton
class MusicLibraryRepositoryImpl implements MusicLibraryRepository {
  MusicLibraryRepositoryImpl(this._dao, this._ossClient);

  final MaiMusicDao _dao;
  final OssApiClient _ossClient;

  @override
  Stream<List<MaiMusic>> watchNormalMusic() {
    return _dao.watchSongs().map(
          (rows) => rows.map(MusicRowMapper.fromNormalTable).toList(),
        );
  }

  @override
  Stream<List<MaiMusic>> watchUtageMusic() {
    return _dao.watchUtageSongs().map(
          (rows) => rows.map(MusicRowMapper.fromUtageTable).toList(),
        );
  }

  @override
  Future<SyncResult> syncFromOss() async {
    int normalCount = 0;
    int utageCount = 0;

    final normalResult = await _ossClient.fetchNormalMusicJson();
    final normalList = normalResult.valueOrNull;
    if (normalList != null) {
      final rows = OssJsonMapper.parseNormalList(normalList);
      await _dao.batchInsertNormal(rows);
      normalCount = rows.length;
    }

    final utageResult = await _ossClient.fetchUtageMusicJson();
    final utageList = utageResult.valueOrNull;
    if (utageList != null) {
      final rows = OssJsonMapper.parseUtageList(utageList);
      await _dao.batchInsertUtage(rows);
      utageCount = rows.length;
    }

    return SyncResult(normalCount: normalCount, utageCount: utageCount);
  }

  @override
  Future<int> countNormal() => _dao.countSongs();

  @override
  Future<int> countUtage() => _dao.countUtageSongs();
}
