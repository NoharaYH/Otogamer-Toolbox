import '../../../domain/entities/token_bundle.dart';
import '../../../domain/entities/vpn_start_config.dart';
import '../../../domain/games/game_module.dart';
import '../../../domain/repositories/music_library_repository.dart';
import '../../../domain/services/html_record_parser.dart';
import '../../../domain/value_objects/difficulty_set.dart';
import '../../../domain/value_objects/transfer_mode.dart';
import '../../../shared/env/app_env.dart';

/// 中二节奏游戏模块：实现 GameModule，提供 VpnStartConfig。
/// 策略对齐舞萌：通过 buildVpnConfig 产出配置，使用 ChunithmConfig。
class ChunithmModule implements GameModule {
  ChunithmModule(this._env, this._musicRepo, this._parser);

  final AppEnv _env;
  final MusicLibraryRepository _musicRepo;
  final HtmlRecordParser _parser;

  @override
  String get gameId => 'chunithm';

  @override
  String get displayName => '中二节奏';

  @override
  String get themeDomainId => 'chunithm';

  @override
  VpnStartConfig buildVpnConfig({
    required TokenBundle tokens,
    required TransferMode mode,
    required DifficultySet difficulties,
  }) {
    final cfg = _env.getTransferConfig(1);
    final wahlapBase = cfg.wahlapBase;
    // 中二不按 genre 细分，按 diff 直接拆分，结构对齐舞萌
    final fetchUrlMap = <int, String>{
      -1: '${wahlapBase}friend/userFriendCode/',
      -2: '${wahlapBase}record/',
      for (final d in difficulties.values)
        if (d >= 0) d: '${wahlapBase}record/musicSort/search/?search=V&sort=1&playCheck=on&diff=$d',
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
      gameTypeIndex: 1,
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
      '$baseUrl/${_env.getTransferConfig(1).lxnsUploadPath}';

  @override
  String divingFishUploadUrl(String baseUrl) =>
      '$baseUrl/${_env.getTransferConfig(1).dfUploadPath}';
}
