import 'mai_music.dart';

/// 曲库双流聚合，供 InitMusicLibraryUsecase 返回。
/// Controller 订阅 normal / utage 以更新 UI。
class MusicLibraryStreams {
  const MusicLibraryStreams({
    required this.normal,
    required this.utage,
  });

  final Stream<List<MaiMusic>> normal;
  final Stream<List<MaiMusic>> utage;
}
