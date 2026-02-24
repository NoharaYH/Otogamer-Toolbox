import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data_formats/mai_music.dart';

class MaiLibrary {
  static const String _kLocalFileName = 'maimai_data_vault.json';

  List<MaiMusic> _musics = [];
  List<MaiMusic> get musics => _musics;

  /// 初始化：仅尝试从本地持久化存储加载 (Vault)
  /// 如果返回 false，说明本地无数据，需要触发 DataSync
  Future<bool> initialize() async {
    return await _loadFromStorage();
  }

  /// 从物理存储读取缓存
  Future<bool> _loadFromStorage() async {
    try {
      final directory =
          await getApplicationSupportDirectory(); // 推荐使用 Support 目录
      final file = File('${directory.path}/$_kLocalFileName');

      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _musics = jsonList.map((j) => MaiMusic.fromJson(j)).toList();
        return true;
      }
    } catch (e) {
      // 加载异常
    }
    return false;
  }

  /// 更新并持久化曲库
  Future<void> updateAndPersist(List<MaiMusic> newSongs) async {
    _musics = newSongs;
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/$_kLocalFileName');
      final jsonContent = jsonEncode(_musics.map((m) => m.toJson()).toList());
      await file.writeAsString(jsonContent);
    } catch (e) {
      // 存储失败处理
    }
  }

  /// 搜索功能
  List<MaiMusic> search(String query) {
    if (query.isEmpty) return _musics;
    return _musics
        .where(
          (m) =>
              m.basicInfo.title.toLowerCase().contains(query.toLowerCase()) ||
              m.basicInfo.id.toString() == query,
        )
        .toList();
  }

  /// 清空缓存（用于强制刷新）
  Future<void> clearCache() async {
    _musics = [];
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/$_kLocalFileName');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
