import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class StorageService {
  final FlutterSecureStorage _storage;

  StorageService(this._storage);

  // Keys
  static const kDivingFishToken = 'df_token';
  static const kLxnsToken = 'lxns_token';
  static const kLxnsTokenPrefix = 'lxns_token_';
  static const kLxnsRefreshTokenPrefix = 'lxns_refresh_token_';
  static const kStartupPrefConfig =
      'startup_pref_config'; // 'Primary:Secondary:Tertiary'
  static const kLastActiveState =
      'last_active_state_cache'; // JSON: {page, game}
  static const kThemePreferences =
      'theme_preferences'; // JSON: {skinId: {colorKey: '#HEX'}}
  static const kActiveSkinId =
      'active_skin_id'; // String: skinId of currently active skin
  static const kThemeMode = 'theme_mode'; // String: 'global' or 'independent'
  static const kMaiSkinId = 'mai_skin_id'; // String: skinId for maimai DX
  static const kChuSkinId = 'chu_skin_id'; // String: skinId for chunithm
  static const kGlassOverlayPrefs = 'glass_overlay_prefs'; // JSON: glass layer opts

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
