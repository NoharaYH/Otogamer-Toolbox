import 'dart:isolate';
import '../../../network/mai_api/mai_client.dart';
import '../transform/mai_transformer.dart';
import '../data_formats/mai_song_row.dart';
import '../../../kernel/services/storage_service.dart';
import '../../../kernel/di/injection.dart';

enum SyncPhase { idle, pulling, merging }

class MaiSyncHandler {
  static const String kMaiDataFingerprint = 'mai_data_fingerprint';
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// 核心同步任务：包含指纹校验守门员逻辑
  Future<List<MaiSongRow>?> performSync({
    bool force = false,
    void Function(SyncPhase)? onPhaseChanged,
    void Function(int current, int total)? onProgress,
  }) async {
    if (_isSyncing) return null;
    _isSyncing = true;
    onPhaseChanged?.call(SyncPhase.pulling);

    final client = MaiClient();
    final storage = getIt<StorageService>();

    try {
      // 1. 获取最新版本指纹 (使用落雪的 version/list 作为参考)
      String latestFingerprint = 'unknown';
      try {
        final versions = await client.fetchVersions();
        if (versions.isNotEmpty) {
          latestFingerprint = versions.last['id'].toString();
        }
      } catch (e) {
        // 指纹获取失败不中断同步，仅记录
        print('MaiSyncHandler: Failed to fetch versions for fingerprint: $e');
      }

      // 2. 导出本地指纹进行对比
      if (!force && latestFingerprint != 'unknown') {
        final localFingerprint = await storage.read(kMaiDataFingerprint);
        if (localFingerprint == latestFingerprint) {
          return null;
        }
      }

      // 3. 并行拉取双端原始数据，采用更稳健的异常处理
      final List<dynamic> dfRaw;
      final List<dynamic> lxRaw;

      try {
        final List<dynamic> results = await Future.wait([
          client.fetchDivingFishRaw().catchError((e) => throw '水鱼曲库拉取失败: $e'),
          client.fetchLxnsRaw().catchError((e) => throw '落雪曲库拉取失败: $e'),
        ]);
        dfRaw = results[0];
        lxRaw = results[1];
      } catch (e) {
        // 如果任何一个源失败，抛出带详细描述的异常
        throw '同步中断: $e';
      }

      // 4. Transformer 全程在独立 Isolate 内运行
      onPhaseChanged?.call(SyncPhase.merging);
      final List<MaiSongRow> rows = await Isolate.run(() async {
        return await MaiTransformer.transform(
          dfRaw,
          lxRaw,
          onProgress: onProgress,
        );
      });

      // 5. 同步成功后，更新本地指纹
      if (latestFingerprint != 'unknown') {
        await storage.save(kMaiDataFingerprint, latestFingerprint);
      }

      return rows;
    } catch (e) {
      rethrow;
    } finally {
      client.dispose();
      _isSyncing = false;
    }
  }
}
