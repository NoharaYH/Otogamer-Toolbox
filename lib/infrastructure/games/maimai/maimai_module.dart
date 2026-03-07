import '../../../domain/entities/token_bundle.dart';
import '../../../domain/entities/vpn_start_config.dart';
import '../../../domain/games/game_module.dart';
import '../../../domain/repositories/music_library_repository.dart';
import '../../../domain/services/html_record_parser.dart';
import '../../../domain/value_objects/difficulty_set.dart';
import '../../../domain/value_objects/transfer_mode.dart';
import '../../../shared/env/app_env.dart';

/// 舞萌 DX 游戏模块：实现 GameModule，提供 VpnStartConfig 与曲库。
class MaimaiModule implements GameModule {
  MaimaiModule(this._env, this._musicRepo, this._parser);

  final AppEnv _env;
  final MusicLibraryRepository _musicRepo;
  final HtmlRecordParser _parser;

  @override
  String get gameId => 'maimai';

  @override
  String get displayName => '舞萌DX';

  @override
  String get themeDomainId => 'maimai';

  @override
  VpnStartConfig buildVpnConfig({
    required TokenBundle tokens,
    required TransferMode mode,
    required DifficultySet difficulties,
  }) {
    final cfg = _env.getTransferConfig(0);
    final wahlapBase = cfg.wahlapBase;
    final fetchUrlMap = <int, String>{
      -1: '${wahlapBase}friend/userFriendCode/',
      -2: '${wahlapBase}record/',
      10: '${wahlapBase}record/musicGenre/search/?genre=99&diff=10',
      for (final d in difficulties.values)
        if (d >= 0 && d != 10)
          d:
              '${wahlapBase}record/musicSort/search/?search=V&sort=1&playCheck=on&diff=$d',
    };
    return VpnStartConfig(
      dfToken: mode.needsDivingFish ? tokens.dfToken : '',
      lxnsToken: mode.needsLxns ? tokens.lxnsToken : '',
      lxnsUploadUrl: '${_env.lxnsBaseUrl}/${cfg.lxnsUploadPath}',
      dfUploadUrl: '${_env.divingFishBaseUrl}/${cfg.dfUploadPath}',
      wahlapBaseUrl: cfg.wahlapBase,
      wahlapAuthUrl: '${_env.wahlapAuthBaseUrl}${cfg.wahlapAuthLabel}',
      genreList: cfg.genreList,
      fetchUrlMap: fetchUrlMap,
      gameTypeIndex: 0,
      difficulties: difficulties.values.toList(),
    );
  }

  @override
  List<Map<String, dynamic>> parseHtmlRecords(String html, int difficulty) =>
      _parser.parse(html);

  @override
  MusicLibraryRepository get musicLibraryRepository => _musicRepo;

  @override
  String lxnsUploadUrl(String baseUrl) =>
      '$baseUrl/${_env.getTransferConfig(0).lxnsUploadPath}';

  @override
  String divingFishUploadUrl(String baseUrl) =>
      '$baseUrl/${_env.getTransferConfig(0).dfUploadPath}';
}
