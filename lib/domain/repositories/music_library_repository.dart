import '../entities/mai_music.dart';
import '../entities/sync_result.dart';

/// 曲库仓储端口：订阅普通曲/宴谱流、同步 OSS、计数。
abstract class MusicLibraryRepository {
  Stream<List<MaiMusic>> watchNormalMusic();
  Stream<List<MaiMusic>> watchUtageMusic();
  Future<SyncResult> syncFromOss();
  Future<int> countNormal();
  Future<int> countUtage();
}
