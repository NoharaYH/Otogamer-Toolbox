class UiStrings {
  // --- App Info ---
  static const String appName = 'OTOKiT';

  // --- Common Actions ---
  static const String confirm = "确认";
  static const String cancel = "取消";
  static const String back = "返回";
  static const String close = "关闭";
  static const String copy = "复制";
  static const String retry = "重试";

  // --- Score Sync ---
  static const String scoreSyncTitle = "成绩同步";
  static const String startImport = "开始传分";
  static const String stopVpn = "停止代理";
  static const String pauseVpn = "暂停传分";
  static const String resumeVpn = "继续传分";
  static const String verifying = "正在验证...";
  static const String verifySuccess = "验证通过，配置已保存";

  // --- Token Form ---
  static const String divingFishAuth = "水鱼 Token 验证";
  static const String lxnsAuth = "落雪 API 验证";
  static const String inputDivingFishToken = "请输入水鱼 Token";
  static const String inputLxnsToken = "请输入落雪 API 密钥";
  static const String tokenHint = "捕获授权码后，同步将在后台自动完成";

  // --- Log Tags ---
  static const String logTagSystem = "[SYSTEM]";
  static const String logTagVersion = "[VERSION]";
  static const String logTagVpn = "[VPN]";
  static const String logTagClipboard = "[CLIPBOARD]";
  static const String logTagAuth = "[AUTH]";
  static const String logTagDownload = "[DOWNLOAD]";
  static const String logTagUpload = "[UPLOAD]";
  static const String logTagError = "[ERROR]";

  // --- Log Messages (Normal Flow) ---
  static const String logSysStart = "传分业务开始";
  static const String logSysUploadFish = "开始上传至水鱼服务器";
  static const String logSysUploadLxns = "开始上传至落雪服务器";
  static const String logSysGetScores = "开始获取用户成绩";
  static const String logSysGetComplete = "成绩获取完毕，开始上传至目标平台...";
  static const String logSysEnd = "传分业务完毕";

  static const String logVpnStarting = "启动本地代理服务...";
  static const String logVpnStarted = "代理服务已启动";
  static const String logVpnClosed = "代理服务已关闭";

  static const String logClipReady = "链接已复制，请前往微信打开";
  static const String logWaitLink = "正在等待链接响应...";

  static const String logAuthStart = "发起微信登录授权...";
  static const String logAuthRedirecting = "已获取授权，正在重定向...";
  static const String logAuthRedirected = "重定向完成，正在获取数据...";

  // --- Log Messages (Templates) ---
  // 使用方法：xxx.replaceAll("{0}", arg1).replaceAll("{1}", arg2)
  static const String logDownloadSuccess = "已获取{0}数据";
  static const String logUploadSuccess = "[{0}] 上传{1}成功";

  // --- Log Messages (Error & Interruptions) ---
  static const String logErrGet = "获取{0}失败: {1} - {2}";
  static const String logErrUpload = "[{0}] 上传{1}失败: {2} - {3}";
  static const String logErrNet = "网络错误，传分业务终止";
  static const String logSysTerminated = "传分业务终止";
  static const String logErrVpnStart = "代理服务启动失败: {0}";
  static const String logErrClip = "剪贴板写入失败";
  static const String logErrToken = "凭证已失效或未授权";
  static const String logErrParse = "解析异常，数据格式不支持";
  static const String logErrUploadToken = "[{0}] 账号未绑定或Token无效";

  // --- Log Messages (Extensions) ---
  static const String logSysPause = "传分业务暂停";
  static const String logSysResume = "传分业务恢复";
  static const String logClipLogCopied = "已复制日志信息";

  // --- Navigation & Core ---
  static const String navScoreSync = "成绩数据同步";
  static const String navMusicData = "歌曲数据图鉴";
  static const String navComingSoon = "敬请期待";

  // --- Prompts & Common ---
  static const String waitTransferEnd = "请等待当前传分进程结束";
  static const String verifyAndSave = "验证并保存 Token";
  static const String confirmEndTransfer = "是否结束传分？";
  static const String waitingLogs = "等待日志输入...";
  static const String pasteConfirm = "是否要粘贴以下内容？";
  static const String returnToToken = "返回授权页面";
  static const String returnToVfToken = "返回Token填写";

  // --- Platform/Mode Names ---
  static const String modeDivingFish = "水鱼";
  static const String modeBoth = "双平台";
  static const String modeLxns = "落雪";
  static const String diffChoiceMai = "选择导入难度";
  static const String diffChoiceChu = "中二传分设置";
  static const String chuDifDev = "中二难度选择器（待开发）";

  // --- Music Sync ---
  static const String pullMusicData = "正在拉取歌曲数据...";
  static const String pullComplete = "拉取完成";
  static const String musicMerge = "合并中...";
  static const String preparing = "准备中...";
  static const String syncing = "正在同步中";
  static const String noMusicDataPrompt = "曲库内暂无歌曲数据\n是否同步？";
  static const String songCountPrefix = "歌曲数: ";
  static const String currentNoMusicData = '当前暂无歌曲数据';
  static const String chuMusicDev = 'Chunithm 曲库开发中';
  // --- Settings ---
  static const String settingsSaved = '设置已保存';
  static const String accountBindSettings = '账号绑定设置';
  static const String divingFishLabel = '水鱼查分器 (Diving-Fish)';
  static const String divingFishImportHint = '请输入水鱼个人资料中的 Import Token';
  static const String divingFishImportHelper = '用于上传成绩到水鱼查分器';
  static const String lxnsLabel = '落雪查分器 (LXNS)';
  static const String lxnsDevTokenLabel = '落雪 API 密钥';
  static const String lxnsDevTokenHint = '授权后可自动获取或手动填入';
  static const String lxnsDevTokenHelper = '此密钥将用于上传 XML/HTML 成绩数据';
  static const String authLxnsVerify = "落雪授权已完成";
  static const String saveConfig = '保存配置';
  static const String authLxnsOAuth = "验证落雪OAuth授权";

  // --- Difficulty Labels (for log) ---
  static const String diffLabelUtage = "U·TA·GE";
  static const String diffLabelWorldsEnd = "World's END";

  // --- OAuth & PKCE ---
  static const String errOAuthNoLaunch = "无法打开授权页面";
  static const String errOAuthNoVerifier = "授权校验失败：丢失 PKCE 凭证";
  static const String oauthSuccess = "落雪 OAuth 授权成功";
  static const String oauthExchangeFailed = "落雪 OAuth 凭证兑换失败";

  // --- Service Status ---
  static const String syncFinish = "传分完成";
  static const String syncTerminated = "传分业务已终止";
  static const String syncPending = "传分业务挂起";
  static const String startProxyService = "正在启动本地代理环境...";
  static const String errInitFailed = "初始化失败: ";

  // --- Settings (Personalization) ---
  static const String personalization = "个性化";
  static const String startupPage = "启动应用时显示的页面";
  static const String startupLast = "以上次退出时的页面为准";
  static const String startupMai = "舞萌 DX (Maimai)";
  static const String startupChu = "中二节奏 (Chunithm)";
}
