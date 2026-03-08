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
    // 中二各难度对应独立路径（对齐 maimaidx-prober）：basic、advanced、expert、master、ultima、worldsEndList
    // diff 0-4 需先 POST 到 sendBasic/sendAdvanced 等（无尾斜杠）再 GET，否则返回空
    const diffPaths = {0: 'basic', 1: 'advanced', 2: 'expert', 3: 'master', 4: 'ultima'};
    const postPaths = {0: 'sendBasic', 1: 'sendAdvanced', 2: 'sendExpert', 3: 'sendMaster', 4: 'sendUltima'};
    final fetchUrlMap = <int, String>{
      -1: '${wahlapBase}home/playerData/',
      -2: '${wahlapBase}record/playlog/',
      for (final d in difficulties.values)
        if (d >= 0)
          d: (d == 10 || d == 5)
              ? '${wahlapBase}record/worldsEndList/'
              : '${wahlapBase}record/musicGenre/${diffPaths[d] ?? 'basic'}',
    };
    final fetchPostUrlMap = <int, String>{
      for (final d in difficulties.values)
        if (d >= 0 && d <= 4 && postPaths.containsKey(d))
          d: '${wahlapBase}record/musicGenre/${postPaths[d]}',
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
      fetchPostUrlMap: fetchPostUrlMap.isEmpty ? null : fetchPostUrlMap,
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
