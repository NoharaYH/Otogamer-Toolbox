import 'dart:async';
import 'package:flutter/material.dart';
import '../../kernel/di/injection.dart';
import '../../kernel/storage/sql/daos/mai_music_dao.dart';
import '../../logic/mai_music_data/data_sync/mai_sync_handler.dart';
import '../../logic/mai_music_data/data_formats/mai_music.dart';
import '../../logic/mai_music_data/transform/mai_db_mapper.dart';

class MaiMusicProvider extends ChangeNotifier {
  final _syncHandler = MaiSyncHandler();
  final _maiMusicDao = getIt<MaiMusicDao>();

  StreamSubscription? _musicSubscription;
  List<MaiMusic> _musics = [];

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
  bool get hasData => _musics.isNotEmpty;
  List<MaiMusic> get musics => _musics;

  @override
  void dispose() {
    _musicSubscription?.cancel();
    super.dispose();
  }

  /// 初始化：启动数据库流监听
  Future<void> init() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    // 订阅主库数据流：当 batchInsert 成功后此处会自动触发更新
    _musicSubscription = _maiMusicDao.watchSongs().listen((rows) {
      _musics = rows.map((r) => MaiDbMapper.fromTable(r)).toList();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    });
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
        // 关键重构：直接落库，无需手动同步进内存，DAO Stream 会负责通知 init() 的订阅者
        await _maiMusicDao.batchInsert(newSongs);
      }
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
    if (query.isEmpty) return _musics;
    final search = query.toLowerCase();
    return _musics
        .where(
          (m) =>
              m.basicInfo.title.toLowerCase().contains(search) ||
              m.basicInfo.id.toString() == search,
        )
        .toList();
  }
}
