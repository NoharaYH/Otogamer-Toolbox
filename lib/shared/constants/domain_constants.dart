/// 业务与日志相关文案，供 domain/application 使用。
/// UI 层可继续使用 [UiStrings]；此处避免 application 依赖 ui/design_system。
class DomainConstants {
  DomainConstants._();

  static const String appName = 'OTOKiT';

  // --- 验证与 Token 提示 ---
  static const String verifySuccess = "验证通过，配置已保存";
  static const String inputDivingFishToken = "请输入水鱼 Token";
  static const String inputLxnsToken = "请输入落雪 API 密钥";

  // --- Log Tags ---
  static const String logTagSystem = "[SYSTEM]";
  static const String logTagVpn = "[VPN]";
  static const String logTagClipboard = "[CLIPBOARD]";
  static const String logTagAuth = "[AUTH]";
  static const String logTagUpload = "[UPLOAD]";
  static const String logTagError = "[ERROR]";

  // --- Log Messages (Normal Flow) ---
  static const String logSysStart = "传分业务开始";
  static const String logVpnStarting = "启动本地代理服务...";
  static const String logVpnStarted = "代理服务已启动";
  static const String logClipReady = "链接已复制，请前往微信打开";
  static const String logWaitLink = "正在等待链接响应...";

  // --- Log Messages (Templates) ---
  static const String logUploadSuccess = "[{0}] 上传{1}成功";
  static const String logErrUpload = "[{0}] 上传{1}失败: {2} - {3}";
  static const String logErrVpnStart = "代理服务启动失败: {0}";
  static const String logErrParse = "解析异常，数据格式不支持";

  // --- Log Messages (Terminated) ---
  static const String logSysTerminated = "传分业务终止";

  // --- Platform/Mode Names (for log/error) ---
  static const String modeDivingFish = "水鱼";
  static const String modeLxns = "落雪";

  // --- Difficulty Labels (for log) ---
  static const String diffLabelUtage = "U·TA·GE";

  // --- OAuth & PKCE ---
  static const String errOAuthNoLaunch = "无法打开授权页面";
  static const String errOAuthNoVerifier = "授权校验失败：丢失 PKCE 凭证";
  static const String oauthSuccess = "落雪 OAuth 授权成功";
  static const String oauthExchangeFailed = "落雪 OAuth 凭证兑换失败";

  // --- Service Status ---
  static const String syncFinish = "传分完成";
}
