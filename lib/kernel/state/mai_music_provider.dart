import 'package:flutter/material.dart';
import '../../logic/mai_music_data/library/mai_library.dart';
import '../../logic/mai_music_data/data_sync/mai_sync_handler.dart';
import '../../logic/mai_music_data/data_formats/mai_music.dart';

class MaiMusicProvider extends ChangeNotifier {
  final MaiLibrary _library = MaiLibrary();
  final MaiSyncHandler _syncHandler = MaiSyncHandler();

  bool _isInitialized = false;
  bool _isLoading = false;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasData => _library.musics.isNotEmpty;
  List<MaiMusic> get musics => _library.musics;

  /// 初始化：检查本地是否有缓存
  Future<void> init() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    await _library.initialize();

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  /// 手动执行同步
  Future<void> sync() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final newSongs = await _syncHandler.performSync(force: true);
      if (newSongs != null) {
        await _library.updateAndPersist(newSongs);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 搜索
  List<MaiMusic> search(String query) => _library.search(query);
}
