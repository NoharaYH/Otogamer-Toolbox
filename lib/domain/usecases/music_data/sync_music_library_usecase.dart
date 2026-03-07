import '../../entities/sync_result.dart';
import '../../repositories/music_library_repository.dart';

/// 从 OSS 同步曲库数据。
class SyncMusicLibraryUsecase {
  const SyncMusicLibraryUsecase(this._repo);
  final MusicLibraryRepository _repo;

  Future<SyncResult> execute() => _repo.syncFromOss();
}
