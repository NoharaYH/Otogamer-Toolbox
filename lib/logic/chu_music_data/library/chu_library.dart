import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data_formats/chu_music.dart';

class ChuLibrary {
  static const String _kLocalFileName = 'chunithm_data_vault.json';
  List<ChuMusic> _musics = [];
  List<ChuMusic> get musics => _musics;

  Future<bool> initialize() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/$_kLocalFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _musics = jsonList.map((j) => ChuMusic.fromJson(j)).toList();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> updateAndPersist(List<ChuMusic> newSongs) async {
    _musics = newSongs;
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/$_kLocalFileName');
      await file.writeAsString(
        jsonEncode(_musics.map((m) => m.toJson()).toList()),
      );
    } catch (_) {}
  }
}
