import 'package:injectable/injectable.dart';

import '../../shared/config/transfer_game_config.dart';
import '../../shared/env/app_env.dart';
import 'chunithm_config.dart';
import 'endpoints.dart';
import 'env.dart';
import 'maimai_config.dart';
import 'system_config.dart';

@lazySingleton
class ProdEnv implements AppEnv {
  const ProdEnv();

  @override
  String get lxnsClientId => Env.lxnsClientId;

  @override
  String get lxnsClientSecret => Env.lxnsClientSecret;

  @override
  int get oauthPort => SystemConfig.oauthPort;

  @override
  String get oauthCallbackPath => SystemConfig.oauthCallbackPath;

  @override
  String get oauthRedirectUri => SystemConfig.oauthRedirectUri;

  @override
  String get oauthScope => SystemConfig.oauthScope;

  @override
  String get oauthDeepLinkHost => SystemConfig.oauthDeepLinkHost;

  @override
  String get oauthRedirectUriDeepLink => SystemConfig.oauthRedirectUriDeepLink;

  @override
  String get proxyBaseUrl => SystemConfig.proxyBaseUrl;

  @override
  String get lxnsBaseUrl => Endpoints.lxnsBaseUrl;

  @override
  String get lxnsAuthorizeUrl => Endpoints.lxnsAuthorize;

  @override
  String get lxnsTokenExchangeUrl => Endpoints.lxnsTokenExchange;

  @override
  String get divingFishBaseUrl => Endpoints.dfBaseUrl;

  @override
  String get wahlapAuthBaseUrl => Endpoints.wahlapAuthBaseUrl;

  @override
  String get ossNormalMusicUrl => Endpoints.ossNormalMusicUrl;

  @override
  String get ossUtageMusicUrl => Endpoints.ossUtageMusicUrl;

  @override
  TransferGameConfig getTransferConfig(int gameType) {
    if (gameType == 1) {
      return TransferGameConfig(
        lxnsUploadPath: ChunithmConfig.lxnsUploadPath,
        dfUploadPath: ChunithmConfig.dfUploadPath,
        wahlapBase: ChunithmConfig.wahlapBase,
        wahlapAuthLabel: ChunithmConfig.wahlapAuthLabel,
        genreList: ChunithmConfig.genreList,
      );
    }
    return TransferGameConfig(
      lxnsUploadPath: MaimaiConfig.lxnsUploadPath,
      dfUploadPath: MaimaiConfig.dfUploadPath,
      wahlapBase: MaimaiConfig.wahlapBase,
      wahlapAuthLabel: MaimaiConfig.wahlapAuthLabel,
      genreList: MaimaiConfig.genreList,
    );
  }
}
