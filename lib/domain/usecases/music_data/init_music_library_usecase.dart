import '../../entities/music_library_streams.dart';
import '../../repositories/music_library_repository.dart';

/// 初始化曲库订阅：返回普通曲与宴谱双流，供 Controller 监听。
class InitMusicLibraryUsecase {
  const InitMusicLibraryUsecase(this._repo);
  final MusicLibraryRepository _repo;

  MusicLibraryStreams execute() => MusicLibraryStreams(
        normal: _repo.watchNormalMusic(),
        utage: _repo.watchUtageMusic(),
      );
}
