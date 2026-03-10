import '../config/transfer_game_config.dart';

/// 运行时环境配置接口，供 infrastructure 与 application 使用。
/// 实现放在 bootstrap/config（ProdEnv），由 DI 注册。
abstract class AppEnv {
  String get lxnsClientId;
  String get lxnsClientSecret;
  String get oauthRedirectUri;
  int get oauthPort;
  String get oauthCallbackPath;
  String get oauthScope;
  String get oauthDeepLinkHost;
  /// Android 专用：OAuth 回调 deep link（落雪重定向后唤起应用）
  String get oauthRedirectUriDeepLink;
  String get proxyBaseUrl;
  String get lxnsBaseUrl;
  String get lxnsAuthorizeUrl;
  String get lxnsTokenExchangeUrl;
  String get divingFishBaseUrl;
  String get wahlapAuthBaseUrl;

  /// OSS 曲库 JSON 地址（未配置时返回空字符串，OssApiClient 将返回 failure）
  String get ossNormalMusicUrl;
  String get ossUtageMusicUrl;

  /// gameType: 0 = maimai, 1 = chunithm
  TransferGameConfig getTransferConfig(int gameType);
}
