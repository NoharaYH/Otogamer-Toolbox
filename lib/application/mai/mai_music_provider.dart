import 'dart:async';
import 'package:flutter/material.dart';
import '../../kernel/di/injection.dart';
import '../../kernel/storage/sql/daos/mai_music_dao.dart';
import '../../logic/mai_music_data/data_sync/mai_sync_handler.dart';
import '../../logic/mai_music_data/data_formats/mai_music.dart';
import '../../logic/mai_music_data/transform/mai_db_mapper.dart';
import '../shared/toast_provider.dart';

class MaiMusicProvider extends ChangeNotifier {
  final _syncHandler = MaiSyncHandler();
  final _maiMusicDao = getIt<MaiMusicDao>();
  final _toastProvider = getIt<ToastProvider>();

  StreamSubscription? _musicSubscription;
  StreamSubscription? _utageSubscription;

  List<MaiMusic> _musics = [];
  List<MaiMusic> _utageMusics = [];
  List<MaiMusic> _allMusics = [];

  bool _isInitialized = false;
  bool _isLoading = false;
  SyncPhase _syncPhase = SyncPhase.idle;
  int _syncCurrent = 0;
  int _syncTotal = 0;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  SyncPhase get syncPhase => _syncPhase;
  int get syncCurrent => _syncCurrent;
  int get syncTotal => _syncTotal;
  bool get hasData => _allMusics.isNotEmpty;
  List<MaiMusic> get musics => _allMusics;

  @override
  void dispose() {
    _musicSubscription?.cancel();
    _utageSubscription?.cancel();
    super.dispose();
  }

  /// 初始化：启动数据库流监听
  Future<void> init() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    // 订阅主库数据流
    _musicSubscription = _maiMusicDao.watchSongs().listen((rows) {
      _musics = rows.map((r) => MaiDbMapper.fromTable(r)).toList();
      _mergeAndNotify();
    });

    // 订阅宴会场数据流
    _utageSubscription = _maiMusicDao.watchUtageSongs().listen((rows) {
      _utageMusics = rows.map((r) => MaiDbMapper.fromUtageTable(r)).toList();
      _mergeAndNotify();
    });
  }

  void _mergeAndNotify() {
    // 合并并排序，保证 UI 渲染一致性
    final combined = [..._musics, ..._utageMusics];
    combined.sort((a, b) => a.basicInfo.id.compareTo(b.basicInfo.id));
    _allMusics = combined;

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  /// 手动执行同步：拉取后批量写入 SQLite
  Future<void> sync() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final newSongs = await _syncHandler.performSync(
        force: true,
        onPhaseChanged: (phase) {
          _syncPhase = phase;
          notifyListeners();
        },
        onProgress: (current, total) {
          _syncCurrent = current;
          _syncTotal = total;
          notifyListeners();
        },
      );

      if (newSongs != null) {
        await _maiMusicDao.batchInsert(newSongs);
        _toastProvider.show(
          "曲库同步成功 (${newSongs.length} 首)",
          ToastType.confirmed,
        );
      } else {
        _toastProvider.show("曲库已是最新", ToastType.confirmed);
      }
    } catch (e) {
      debugPrint('MaiMusicProvider: Sync failed: $e');
      _toastProvider.show("同步失败: $e", ToastType.error);
    } finally {
      _isLoading = false;
      _syncPhase = SyncPhase.idle;
      _syncCurrent = 0;
      _syncTotal = 0;
      notifyListeners();
    }
  }

  /// 搜索：基于内存当前快照进行快速模糊匹配
  List<MaiMusic> search(String query) {
    if (query.isEmpty) return _allMusics;
    final search = query.toLowerCase();
    return _allMusics
        .where(
          (m) =>
              m.basicInfo.title.toLowerCase().contains(search) ||
              m.basicInfo.id.toString() == search,
        )
        .toList();
  }
}
