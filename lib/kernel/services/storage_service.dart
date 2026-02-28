import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class StorageService {
  final FlutterSecureStorage _storage;

  StorageService(this._storage);

  // Keys
  static const kDivingFishToken = 'df_token';
  static const kLxnsToken = 'lxns_token';
  static const kStartupPage = 'startup_page'; // 'mai' | 'chu' | 'last'
  static const kLastExitPage = 'last_exit_page'; // '0' | '1'

  // Generic Write
  Future<void> save(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Generic Read
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  // Clear
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
