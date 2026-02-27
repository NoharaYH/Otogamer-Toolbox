import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String lxnsToken = '';
  String? lxnsRefreshToken;
  String? _pkceVerifier; // PKCE 原始校验码

  // UI 状态
  bool _isLoading = false;
  bool _isStorageLoaded = false;
  bool _isDivingFishVerified = false;
  bool _isLxnsVerified = false;
  bool _isVpnRunning = false;
  bool _isTracking = false;
  int? _trackingGameType;
  Set<int> _currentDifficulties = {0, 1, 2, 3, 4, 5};
  String? _errorMessage;
  String? _successMessage;
  final Map<int, String> _gameLogs = {};

  static const _channel = MethodChannel('com.noharayh.otokit/vpn');

  // Getters
  bool get isLoading => _isLoading;
  bool get isStorageLoaded => _isStorageLoaded;
  bool get isDivingFishVerified => _isDivingFishVerified;
  bool get isLxnsVerified => _isLxnsVerified;
  bool get isVpnRunning => _isVpnRunning;
  bool get isTracking => _isTracking;
  int? get trackingGameType => _trackingGameType;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get vpnLog => _gameLogs[_trackingGameType] ?? "";
  String getVpnLog(int gameType) => _gameLogs[gameType] ?? "";

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
      if (uri.scheme == 'https' &&
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
  Future<void> startLxnsOAuthFlow() async {
    _pkceVerifier = _generateRandomString(128);
    final challenge = _computeChallenge(_pkceVerifier!);

    // 假设 clientId 为 1, scope 为全权限
    const clientId = "1";
    final state = base64Url.encode(
      utf8.encode("tenant=lxns&nonce=${_generateRandomString(8)}"),
    );

    final url = Uri.parse(
      "https://maimai.lxns.net/oauth/authorize"
      "?client_id=$clientId"
      "&redirect_uri=${Uri.encodeComponent("https://app.otokit.com/oauth/callback")}"
      "&response_type=code"
      "&scope=read+write"
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

    const clientId = "1";
    final result = await _apiService.exchangeLxnsCode(
      code,
      clientId,
      _pkceVerifier!,
    );

    if (result != null) {
      lxnsToken = result['access_token'];
      lxnsRefreshToken = result['refresh_token'];
      _isLxnsVerified = true;
      _pkceVerifier = null; // 消费后清理

      await _storageService.save(StorageService.kLxnsToken, lxnsToken);
      if (lxnsRefreshToken != null) {
        await _storageService.save("lxns_refresh_token", lxnsRefreshToken!);
      }
      _successMessage = UiStrings.oauthSuccess;
    } else {
      _errorMessage = UiStrings.oauthExchangeFailed;
    }

    _isLoading = false;
    notifyListeners();
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
            startVpn();
          }
          break;
      }
    });
  }

  Future<void> startVpn() async {
    final ok = await _channel.invokeMethod<bool>('prepareVpn');
    if (ok == true) {
      // 将 Token 凭证与难度配置一同下发，供原生 DataContext 存储后使用
      await _channel.invokeMethod('startVpn', {
        'username': dfToken,
        'password': lxnsToken,
        'gameType': _trackingGameType,
        'difficulties': _currentDifficulties.toList(),
      });
    }
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
    Set<int> difficulties = const {0, 1, 2, 3, 4, 5},
  }) async {
    _isTracking = true;
    _trackingGameType = gameType;
    _currentDifficulties = difficulties;
    _gameLogs[gameType] = "";
    notifyListeners();

    appendLog("${UiStrings.logTagSystem} ${UiStrings.logSysStart}");
    appendLog("${UiStrings.logTagVpn} ${UiStrings.logVpnStarting}");

    try {
      await startVpn();

      // 使用随机 Path 防止微信浏览器缓存上一次的重定向
      final randomStr = DateTime.now().millisecondsSinceEpoch
          .toRadixString(36)
          .substring(0, 8);
      final localProxyUrl = "http://127.0.0.2:8284/$randomStr";
      await Clipboard.setData(ClipboardData(text: localProxyUrl));

      appendLog("${UiStrings.logTagVpn} ${UiStrings.logVpnStarted}");
      appendLog("${UiStrings.logTagClipboard} ${UiStrings.logClipReady}");
      appendLog(UiStrings.logWaitLink);
    } catch (e) {
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
    final lxns = await _storageService.read(StorageService.kLxnsToken);

    if (df != null && df.isNotEmpty) {
      dfToken = df;
      _isDivingFishVerified = true;
    }
    if (lxns != null && lxns.isNotEmpty) {
      lxnsToken = lxns;
      _isLxnsVerified = true;
    }
    lxnsRefreshToken = await _storageService.read("lxns_refresh_token");
    _isStorageLoaded = true;
    notifyListeners();
  }

  void resetVerification({bool df = false, bool lxns = false}) {
    if (df) _isDivingFishVerified = false;
    if (lxns) _isLxnsVerified = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void updateTokens({String? df, String? lxns}) {
    if (df != null) {
      dfToken = df;
      _isDivingFishVerified = false;
    }
    if (lxns != null) {
      lxnsToken = lxns;
      _isLxnsVerified = false;
    }
    notifyListeners();
  }

  Future<bool> verifyAndSave({required int mode}) async {
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
    if (needsLxns && lxnsToken.isEmpty) {
      _errorMessage = UiStrings.inputLxnsToken;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      bool dfSuccess = _isDivingFishVerified;
      bool lxnsSuccess = _isLxnsVerified;

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
        lxnsSuccess = await _apiService.validateLxnsToken(lxnsToken);
        if (!lxnsSuccess) {
          _errorMessage = "${UiStrings.modeLxns} ${UiStrings.logTagAuth} 验证失败";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _isDivingFishVerified = dfSuccess;
      _isLxnsVerified = lxnsSuccess;

      if (dfSuccess) {
        await _storageService.save(StorageService.kDivingFishToken, dfToken);
      }
      if (lxnsSuccess) {
        await _storageService.save(StorageService.kLxnsToken, lxnsToken);
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
