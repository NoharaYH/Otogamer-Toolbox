class SystemConfig {
  // Method Channel
  static const String vpnChannelName = 'com.noharayh.otokit/vpn';

  // OAuth Settings
  static const int oauthPort = 34125;
  static const String oauthCallbackPath = '/oauth/callback';
  static const String oauthRedirectUri =
      "http://127.0.0.1:$oauthPort$oauthCallbackPath";
  static const String oauthDeepLinkHost = 'app.otokit.com';
  /// Android 专用：OAuth 回调 deep link（包名 host，用于第三方浏览器唤起应用）
  static const String oauthRedirectUriDeepLink =
      'otokit://com.noharayh.otokit/oauth/callback';
  static const String oauthScope =
      "read_user_profile+read_player+write_player+read_user_token";

  // Proxy Settings
  static const String proxyBaseUrl = "http://127.0.0.2:8284";
}
