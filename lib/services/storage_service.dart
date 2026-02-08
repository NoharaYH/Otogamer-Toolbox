import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const kDivingFishToken = 'df_token';
  static const kLxnsToken = 'lxns_token';
  static const kMaimaiCookie = 'maimai_cookie';
  static const kChunithmCookie = 'chunithm_cookie';

  // Generic Write
  static Future<void> save(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Generic Read
  static Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  // Clear
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
