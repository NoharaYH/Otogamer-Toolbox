class Endpoints {
  // Diving Fish (水鱼/查分器)
  static const String dfBaseUrl = "https://www.diving-fish.com/api";

  // NOTE: Validation and JSON Upload for Maimai
  static const String dfMaimaiRecords =
      "$dfBaseUrl/maimaidxprober/player/records";
  static const String dfMaimaiUpload =
      "$dfBaseUrl/maimaidxprober/player/update_records";

  // LXNS (落雪/落雪查分器)
  static const String lxnsBaseUrl = "https://maimai.lxns.net/api/v0";
  static const String lxnsAuthorize = "https://maimai.lxns.net/oauth/authorize";
  static const String lxnsTokenExchange = "$lxnsBaseUrl/oauth/token";

  // Wahlap Auth (微信授权基础地址)
  static const String wahlapAuthBaseUrl =
      "https://tgk-wcaime.wahlap.com/wc_auth/oauth/authorize/";

  /// OSS 曲库 JSON（实际 URL 可放在 test/sql/secrets/oss_urls.json 等，此处占位）
  static const String ossNormalMusicUrl = '';
  static const String ossUtageMusicUrl = '';
}
