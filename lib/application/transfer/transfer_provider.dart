import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../kernel/config/env.dart';
import '../../kernel/services/storage_service.dart';
import '../../kernel/services/api_service.dart';
import '../../ui/design_system/constants/strings.dart';

/// TransferProvider：纯 UI 状态中转层。
@injectable
class TransferProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // 数据状态
  String dfToken = '';
  String lxnsToken = ''; // 当前游戏类型的 LXNS Token
  // 按游戏隔离存储：0 = maimai, 1 = chunithm
  final Map<int, String> _lxnsTokens = {};
  final Map<int, String?> _lxnsRefreshTokens = {};
  final Map<int, bool> _isLxnsOAuthDoneMap = {};
  String? get lxnsRefreshToken => _lxnsRefreshTokens[_trackingGameType ?? 0];
  String? _pkceVerifier; // PKCE 原始校验码

  // UI 状态
  bool _isLoading = false;
  bool _isStorageLoaded = false;
  final Map<int, bool> _isDivingFishVerifiedMap = {};
  final Map<int, bool> _isLxnsVerifiedMap = {};
  bool _isVpnRunning = false;
  bool _isTracking = false;
  bool _pendingWechat = false; // 等 VPN 真正启动后再跳微信
  int? _trackingGameType;
  int _oauthTargetGameType = 0; // 记录本次 OAuth 的目标游戏类型
  int _lastMode = 0; // 记录最近一次启动模式，供权限回调恢复使用
  Set<int> _currentDifficulties = {0, 1, 2, 3, 4, 5};
  String? _errorMessage;
  String? _successMessage;
  final Map<int, String> _gameLogs = {};

  static const _channel = MethodChannel('com.noharayh.otokit/vpn');

  // Getters (Legacy - primarily for back-compat or active tab)
  bool get isLoading => _isLoading;
  bool get isStorageLoaded => _isStorageLoaded;
  bool get isDivingFishVerified =>
      _isDivingFishVerifiedMap[_activeGameType] ?? false;
  bool get isLxnsVerified => _isLxnsVerifiedMap[_activeGameType] ?? false;
  bool get isVpnRunning => _isVpnRunning;
  bool get isTracking => _isTracking;
  int? get trackingGameType => _trackingGameType;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get vpnLog => _gameLogs[_trackingGameType] ?? "";
  String getVpnLog(int gameType) => _gameLogs[gameType] ?? "";
  bool get isLxnsOAuthDone => _isLxnsOAuthDoneMap[_activeGameType] ?? false;

  bool isDivingFishVerifiedFor(int gameType) =>
      _isDivingFishVerifiedMap[gameType] ?? false;
  bool isLxnsVerifiedFor(int gameType) => _isLxnsVerifiedMap[gameType] ?? false;
  bool isLxnsOAuthDoneFor(int gameType) =>
      _isLxnsOAuthDoneMap[gameType] ?? false;
  String lxnsTokenFor(int gameType) => _lxnsTokens[gameType] ?? '';

  // 当前选中的游戏类型（表单页中接收）
  int _activeGameType = 0;
  void setActiveGameType(int gameType) {
    _activeGameType = gameType;
    lxnsToken = _lxnsTokens[gameType] ?? '';
    notifyListeners();
  }

  Timer? _logNotifyTimer;

  TransferProvider(this._apiService, this._storageService) {
    _loadTokens();
    _initChannel();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('[DEEPLINK] Incoming: $uri');
      // 统一入口: /oauth/callback
      if ((uri.scheme == 'https' || uri.scheme == 'otokit') &&
          uri.host == 'app.otokit.com' &&
          uri.path == '/oauth/callback') {
        final state = uri.queryParameters['state'];
        final code = uri.queryParameters['code'];

        // 逻辑分发：识别 tenant=lxns
        if (state != null && state.contains('lxns') && code != null) {
          await _handleLxnsOAuth(code);
        }
      }
    });
  }

  /// 发起落雪 OAuth 授权流程 (PKCE)
  /// [gameType]: 0 = maimai, 1 = chunithm
  Future<void> startLxnsOAuthFlow({int gameType = 0}) async {
    _oauthTargetGameType = gameType;
    _pkceVerifier = _generateRandomString(128);
    final challenge = _computeChallenge(_pkceVerifier!);

    final state = base64Url.encode(
      utf8.encode("tenant=lxns&nonce=${_generateRandomString(8)}"),
    );

    // 统一 OAuth Scope：LXNS 采用通用权限标识，涵盖所有关联游戏
    const String scope =
        "read_user_profile+read_player+write_player+read_user_token";

    const int oauthPort = 34125;
    final String redirectUri = "http://127.0.0.1:$oauthPort/oauth/callback";

    try {
      final server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        oauthPort,
        shared: true,
      );
      server.listen((HttpRequest request) async {
        if (request.uri.path == '/oauth/callback') {
          final code = request.uri.queryParameters['code'];
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write(
              '<meta charset="utf-8"><body><h2 style="text-align:center;margin-top:50px;">授权成功！您可以关闭此网页并返回 OtoKit。</h2></body>',
            );
          await request.response.close();
          await server.close(force: true);

          if (code != null) {
            _handleLxnsOAuth(code);
          }
        }
      });
      // 超时防护：5分钟后自动关闭监听
      Future.delayed(const Duration(minutes: 5), () {
        server.close(force: true);
      });
    } catch (e) {
      debugPrint("[OAuth] Server bind error: $e");
    }

    final url = Uri.parse(
      "https://maimai.lxns.net/oauth/authorize"
      "?client_id=${Env.lxnsClientId}"
      "&redirect_uri=${Uri.encodeComponent(redirectUri)}"
      "&response_type=code"
      "&scope=$scope"
      "&state=$state"
      "&code_challenge=$challenge"
      "&code_challenge_method=S256",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _errorMessage = UiStrings.errOAuthNoLaunch;
      notifyListeners();
    }
  }

  Future<void> _handleLxnsOAuth(String code) async {
    if (_pkceVerifier == null) {
      _errorMessage = UiStrings.errOAuthNoVerifier;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.exchangeLxnsCode(
        code,
        Env.lxnsClientId,
        Env.lxnsClientSecret,
        _pkceVerifier!,
      );

      if (result != null) {
        final accessToken = result['access_token'] as String;
        final refreshToken = result['refresh_token'] as String?;
        final gt = _oauthTargetGameType;

        // 按游戏类型隔离存储凭证
        _lxnsTokens[gt] = accessToken;
        _lxnsRefreshTokens[gt] = refreshToken;
        _isLxnsOAuthDoneMap[gt] = true;
        _isLxnsVerifiedMap[gt] = true;
        lxnsToken = accessToken; // 同步公开字段
        _pkceVerifier = null;

        final tokenKey = 'lxns_token_$gt';
        final refreshKey = 'lxns_refresh_token_$gt';
        await _storageService.save(tokenKey, accessToken);
        if (refreshToken != null) {
          await _storageService.save(refreshKey, refreshToken);
        }
        _successMessage = UiStrings.oauthSuccess;
      } else {
        _errorMessage = UiStrings.oauthExchangeFailed;
      }
    } catch (e) {
      debugPrint('[OAuth] Token exchange exception: $e');
      _errorMessage = '[OAuth] 字符交换异常: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // PKCE Helper Functions
  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _computeChallenge(String verifier) {
    final bytes = ascii.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  void _handleLog(String msg) {
    if (_trackingGameType == null) return;
    // 同时输出到 IDE 调试控制台，响应“控制台内部 print”要求
    print(msg);
    _gameLogs[_trackingGameType!] =
        "${_gameLogs[_trackingGameType!] ?? ""}$msg\n";

    // 对于关键操作标记，立即通知 UI 避免 100ms 防抖带来的视觉滞后
    if (msg.contains('[PAUSE]') ||
        msg.contains('[RESUME]') ||
        msg.contains('[START]')) {
      _logNotifyTimer?.cancel();
      notifyListeners();
      return;
    }

    // 普通日志保持防抖，避免高频重建
    if (_logNotifyTimer?.isActive ?? false) return;
    _logNotifyTimer = Timer(const Duration(milliseconds: 100), () {
      notifyListeners();
    });
  }

  /// 向控制台追加一行日志（UI 层调用，走防抖通知路径）。
  void appendLog(String msg) => _handleLog(msg);

  void _initChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onStatusChanged':
          _isVpnRunning = call.arguments['isRunning'];
          final status = call.arguments['status'] as String?;
          if (status != null) _successMessage = status;

          // 根据 MainActivity 的推送语义分离业务生命周期：
          // [DONE] 推送: status="传分完成", isRunning=false
          // [ERROR] 推送: status=null, isRunning=false
          if (status == UiStrings.syncFinish ||
              (status == null && !_isVpnRunning)) {
            _isTracking = false;
            // 显式保留 _trackingGameType 以避免 SyncLogPanel 被 auto-hidden 机制强制折叠
            stopVpn(resetState: false);
          }
          notifyListeners();
          break;
        case 'onLogReceived':
          _handleLog(call.arguments as String);
          break;
        case 'onVpnPrepared':
          if (call.arguments == true) {
            await startVpn(mode: _lastMode);
          }
          break;
      }
    });
  }

  Future<void> startVpn({required int mode}) async {
    final ok = await _channel.invokeMethod<bool>('prepareVpn');
    if (ok == true) {
      // 根据 mode 决定下发的 Token
      final finalDfToken = (mode == 0 || mode == 1) ? dfToken : "";
      final finalLxnsToken = (mode == 2 || mode == 1)
          ? (_lxnsTokens[_trackingGameType ?? 0] ?? "")
          : "";

      // 将 Token 凭证与难度配置一同下发，供原生 DataContext 存储后使用
      await _channel.invokeMethod('startVpn', {
        'username': finalDfToken,
        'password': finalLxnsToken,
        'gameType': _trackingGameType,
        'isLxnsOAuth':
            _isLxnsOAuthDoneMap[_trackingGameType ?? 0] ?? false, // 设置鉴权模式标识
        'difficulties': _currentDifficulties.toList(),
      });
      // VPN 已实际启动，此时再执行微信跳转
      if (_pendingWechat) {
        _pendingWechat = false;
        await _afterVpnReady();
      }
    }
  }

  /// VPN 实际启动后执行：写剪贴板、跳微信、打印日志。
  /// 由 startVpn 在两条路径（直接授权 / onVpnPrepared 回调）收口调用。
  Future<void> _afterVpnReady() async {
    final randomStr = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .substring(0, 8);
    final localProxyUrl = "http://127.0.0.2:8284/$randomStr";
    await Clipboard.setData(ClipboardData(text: localProxyUrl));

    final wxUrl = Uri.parse("weixin://");
    if (await canLaunchUrl(wxUrl)) {
      await launchUrl(wxUrl, mode: LaunchMode.externalApplication);
    }

    appendLog("${UiStrings.logTagVpn} ${UiStrings.logVpnStarted}");
    appendLog("${UiStrings.logTagClipboard} ${UiStrings.logClipReady}");
    appendLog(UiStrings.logWaitLink);
  }

  Future<bool> stopVpn({
    bool resetState = true,
    bool isManually = false,
  }) async {
    if (isManually) {
      appendLog("${UiStrings.logTagSystem} ${UiStrings.logSysTerminated}");
    }
    await _channel.invokeMethod('stopVpn');
    if (resetState) {
      if (_trackingGameType != null && isManually) {
        // 手动终止时清理对应游戏的日志缓存，实现彻底隔离
        _gameLogs.remove(_trackingGameType);
      }
      _isTracking = false;
      _trackingGameType = null;
    }
    notifyListeners();
    return true;
  }

  void startTracking({required int gameType}) {
    _isTracking = true;
    _trackingGameType = gameType;
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    _trackingGameType = null;
    notifyListeners();
  }

  Future<void> startImport({
    required int gameType,
    required int mode,
    Set<int> difficulties = const {0, 1, 2, 3, 4, 5},
  }) async {
    _isTracking = true;
    _trackingGameType = gameType;
    _lastMode = mode;
    _currentDifficulties = difficulties;
    _gameLogs[gameType] = "";
    notifyListeners();

    appendLog("${UiStrings.logTagSystem} ${UiStrings.logSysStart}");
    appendLog("${UiStrings.logTagVpn} ${UiStrings.logVpnStarting}");

    try {
      _pendingWechat = true;
      await startVpn(mode: mode);
      // 到这里有两种情况：
      // 1. 已有 VPN 权限 → startVpn 内部已调用 _afterVpnReady，_pendingWechat=false
      // 2. 首次需要授权 → 系统弹窗未关闭，_pendingWechat 保持 true；
      //    用户点击允许后 onVpnPrepared 触发 startVpn()，届时再执行 _afterVpnReady
    } catch (e) {
      _pendingWechat = false;
      appendLog(UiStrings.logErrVpnStart.replaceAll("{0}", e.toString()));
    }
  }

  @override
  void dispose() {
    _logNotifyTimer?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTokens() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final df = await _storageService.read(StorageService.kDivingFishToken);
    if (df != null && df.isNotEmpty) {
      dfToken = df;
      for (final gt in [0, 1]) {
        _isDivingFishVerifiedMap[gt] = true;
      }
    }

    // 按游戏隔离加载 LXNS Token
    for (final gt in [0, 1]) {
      final tokenKey = 'lxns_token_$gt';
      final refreshKey = 'lxns_refresh_token_$gt';
      final lxns = await _storageService.read(tokenKey);
      final refresh = await _storageService.read(refreshKey);

      if (lxns != null && lxns.isNotEmpty) {
        _lxnsTokens[gt] = lxns;
        _isLxnsVerifiedMap[gt] = true;
      }
      if (refresh != null && refresh.isNotEmpty) {
        _lxnsRefreshTokens[gt] = refresh;
      }

      // access_token 寿命 15 分钟，启动时若有 refresh_token 则静默续期
      final refreshToken = _lxnsRefreshTokens[gt];
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final refreshed = await _apiService.refreshLxnsToken(
            refreshToken,
            Env.lxnsClientId,
            Env.lxnsClientSecret,
          );
          if (refreshed != null) {
            final newAccess = refreshed['access_token'] ?? _lxnsTokens[gt];
            final newRefresh = refreshed['refresh_token'] ?? refreshToken;
            _lxnsTokens[gt] = newAccess;
            _lxnsRefreshTokens[gt] = newRefresh;
            _isLxnsVerifiedMap[gt] = true;
            _isLxnsOAuthDoneMap[gt] = true;
            await _storageService.save('lxns_token_$gt', newAccess);
            await _storageService.save('lxns_refresh_token_$gt', newRefresh);
          }
        } catch (_) {
          // 静默失败：保留上次 token，由实际传分时暴露错误
        }
      }
    }

    // 将当前激活游戏的 token 同步到公开字段
    lxnsToken = _lxnsTokens[_activeGameType] ?? '';
    _isStorageLoaded = true;
    notifyListeners();
  }

  void resetVerification({int? gameType, bool df = false, bool lxns = false}) {
    final targetGt = gameType ?? _activeGameType;
    if (df) _isDivingFishVerifiedMap[targetGt] = false;
    if (lxns) _isLxnsVerifiedMap[targetGt] = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void updateTokens({int? gameType, String? df, String? lxns}) {
    final targetGt = gameType ?? _activeGameType;
    if (df != null) {
      dfToken = df;
      // 水鱼 Token 全局同步，但需要重置所有游戏的验证状态
      for (final gt in [0, 1]) {
        _isDivingFishVerifiedMap[gt] = false;
      }
    }
    if (lxns != null) {
      _lxnsTokens[targetGt] = lxns;
      _isLxnsVerifiedMap[targetGt] = false;
      // 不要设置 OAuthDone 位，因为手动输入的可能是个人 API Key
      _isLxnsOAuthDoneMap[targetGt] = false;
    }
    notifyListeners();
  }

  Future<bool> verifyAndSave({required int mode, required int gameType}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    final needsDf = mode == 0 || mode == 1;
    final needsLxns = mode == 2 || mode == 1;

    if (needsDf && dfToken.isEmpty) {
      _errorMessage = UiStrings.inputDivingFishToken;
      _isLoading = false;
      notifyListeners();
      return false;
    }
    final currentLxnsToken = _lxnsTokens[gameType] ?? "";
    if (needsLxns && currentLxnsToken.isEmpty) {
      _errorMessage = UiStrings.inputLxnsToken;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      bool dfSuccess = _isDivingFishVerifiedMap[gameType] ?? false;
      bool lxnsSuccess = _isLxnsVerifiedMap[gameType] ?? false;

      if (needsDf && !dfSuccess) {
        dfSuccess = await _apiService.validateDivingFishToken(dfToken);
        if (!dfSuccess) {
          _errorMessage =
              "${UiStrings.modeDivingFish} ${UiStrings.logTagAuth} 验证失败";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      if (needsLxns && !lxnsSuccess) {
        lxnsSuccess = await _apiService.validateLxnsToken(
          currentLxnsToken,
          gameType: gameType,
          isOAuth: _isLxnsOAuthDoneMap[gameType] ?? false,
        );
        if (!lxnsSuccess) {
          _errorMessage = "${UiStrings.modeLxns} ${UiStrings.logTagAuth} 验证失败";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _isDivingFishVerifiedMap[gameType] = dfSuccess;
      _isLxnsVerifiedMap[gameType] = lxnsSuccess;

      if (dfSuccess) {
        await _storageService.save(StorageService.kDivingFishToken, dfToken);
      }
      if (lxnsSuccess) {
        _lxnsTokens[gameType] = currentLxnsToken;
        await _storageService.save('lxns_token_$gameType', currentLxnsToken);
      }

      _successMessage = UiStrings.verifySuccess;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "验证过程发生错误: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
