import 'dart:async';
import 'package:flutter/material.dart';
import '../di/injection.dart';
import '../storage/sql/daos/mai_music_dao.dart';
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

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
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

    _musicSubscription = _maiMusicDao.watchSongs().listen((rows) {
      _musics = rows.map((r) => MaiDbMapper.fromTable(r)).toList();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    });
  }

  /// 手动执行同步
  Future<void> sync() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final newSongs = await _syncHandler.performSync(force: true);
      if (newSongs != null) {
        await _maiMusicDao.batchInsert(newSongs);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 搜索
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
