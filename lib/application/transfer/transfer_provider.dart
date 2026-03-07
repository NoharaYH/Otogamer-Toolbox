import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/token_bundle.dart';
import '../../domain/entities/vpn_start_config.dart';
import '../../domain/entities/vpn_status.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../../domain/repositories/vpn_repository.dart';
import '../../domain/services/html_record_parser.dart';
import '../../domain/value_objects/game_type.dart';
import '../../infrastructure/network/oauth/pkce_helper.dart';
import '../../shared/constants/domain_constants.dart';
import '../../shared/env/app_env.dart';

/// TransferProvider：纯 UI 状态中转层。
@injectable
class TransferProvider extends ChangeNotifier {
  TransferProvider(
    this._authRepo,
    this._transferRepo,
    this._vpnRepo,
    this._env,
    this._htmlParser,
  ) {
    _loadTokens();
    _statusSubscription = _vpnRepo.statusStream.listen(_onVpnStatus);
    _logSubscription = _vpnRepo.logStream.listen(_handleLog);
    _initDeepLinks();
  }

  final AuthRepository _authRepo;
  final TransferRepository _transferRepo;
  final VpnRepository _vpnRepo;
  final AppEnv _env;
  final HtmlRecordParser _htmlParser;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<VpnStatus>? _statusSubscription;
  StreamSubscription<String>? _logSubscription;

  // 数据状态
  String dfToken = '';
  // 统一身份凭证：落雪 (LXNS) 账号全局唯一，不再按游戏隔离
  String lxnsToken = '';
  String? lxnsRefreshToken;
  bool _isLxnsOAuthDone = false;
  String? _pkceVerifier; // PKCE 原始校验码

  // UI 状态
  bool _isLoading = false;
  bool _isStorageLoaded = false;
  final Map<int, bool> _isDivingFishVerifiedMap = {};
  bool _isLxnsVerified = false;
  bool _isVpnRunning = false;
  bool _isTracking = false;
  bool _pendingWechat = false; // 等 VPN 真正启动后再跳微信
  int? _trackingGameType;
  Set<int> _currentDifficulties = {0, 1, 2, 3, 4, 5};
  String? _errorMessage;
  String? _successMessage;
  final Map<int, String> _gameLogs = {};

  // Getters (Legacy - primarily for back-compat or active tab)
  bool get isLoading => _isLoading;
  bool get isStorageLoaded => _isStorageLoaded;
  bool get isDivingFishVerified =>
      _isDivingFishVerifiedMap[_activeGameType] ?? false;
  bool get isLxnsVerified => _isLxnsVerified;
  bool get isVpnRunning => _isVpnRunning;
  bool get isTracking => _isTracking;
  int? get trackingGameType => _trackingGameType;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get vpnLog => _gameLogs[_trackingGameType] ?? "";
  String getVpnLog(int gameType) => _gameLogs[gameType] ?? "";
  bool get isLxnsOAuthDone => _isLxnsOAuthDone;

  bool isDivingFishVerifiedFor(int gameType) =>
      _isDivingFishVerifiedMap[gameType] ?? false;
  bool isLxnsVerifiedFor(int gameType) => _isLxnsVerified;
  bool isLxnsOAuthDoneFor(int gameType) => _isLxnsOAuthDone;
  String lxnsTokenFor(int gameType) => lxnsToken;

  // 当前选中的游戏类型（表单页中接收）
  int _activeGameType = 0;
  void setActiveGameType(int gameType) {
    _activeGameType = gameType;
    notifyListeners();
  }

  Timer? _logNotifyTimer;

  void _onVpnStatus(VpnStatus status) {
    _isVpnRunning = status.isRunning;
    if (status.statusText != null) _successMessage = status.statusText;
    if (status.isDone || status.statusText == DomainConstants.syncFinish) {
      _isTracking = false;
      _vpnRepo.stop();
    }
    if (status.isRunning && _pendingWechat) {
      _pendingWechat = false;
      _afterVpnReady();
    }
    notifyListeners();
  }

  void _initDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('[DEEPLINK] Incoming: $uri');
      if ((uri.scheme == 'https' || uri.scheme == 'otokit') &&
          uri.host == _env.oauthDeepLinkHost &&
          uri.path == _env.oauthCallbackPath) {
        final state = uri.queryParameters['state'];
        final code = uri.queryParameters['code'];
        if (state != null && code != null) {
          final decoded = utf8.decode(base64Url.decode(state));
          if (decoded.contains('tenant=lxns')) {
            int gt = 0;
            if (decoded.contains('gameType=1')) gt = 1;
            await _handleLxnsOAuth(code, gameType: gt);
          }
        }
      }
    });
  }

  /// 发起落雪 OAuth 授权流程 (PKCE)
  /// [gameType]: 0 = maimai, 1 = chunithm
  Future<void> startLxnsOAuthFlow({int gameType = 0}) async {
    _pkceVerifier = PkceHelper.generateVerifier();
    final challenge = PkceHelper.computeChallenge(_pkceVerifier!);

    final state = base64Url.encode(
      utf8.encode(
        "tenant=lxns&gameType=$gameType&nonce=${PkceHelper.generateVerifier(length: 8)}",
      ),
    );

    final scope = _env.oauthScope;
    final oauthPort = _env.oauthPort;
    final redirectUri = _env.oauthRedirectUri;

    try {
      final server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        oauthPort,
        shared: true,
      );
      server.listen((HttpRequest request) async {
        if (request.uri.path == _env.oauthCallbackPath) {
          final code = request.uri.queryParameters['code'];
          final stateParam = request.uri.queryParameters['state'];
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write(
              '<meta charset="utf-8"><body><h2 style="text-align:center;margin-top:50px;">${DomainConstants.oauthSuccess}！您可以关闭此网页并返回 ${DomainConstants.appName}。</h2></body>',
            );
          await request.response.close();
          await server.close(force: true);

          if (code != null) {
            int gt = 0;
            if (stateParam != null) {
              final decoded = utf8.decode(base64Url.decode(stateParam));
              if (decoded.contains('gameType=1')) gt = 1;
            }
            await _handleLxnsOAuth(code, gameType: gt);
          }
        }
      });
      Future.delayed(const Duration(minutes: 5), () {
        server.close(force: true);
      });
    } catch (e) {
      debugPrint("[OAuth] Server bind error: $e");
    }

    final url = Uri.parse(
      '${_env.lxnsAuthorizeUrl}'
      '?client_id=${_env.lxnsClientId}'
      '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
      '&response_type=code'
      '&scope=$scope'
      '&state=$state'
      '&code_challenge=$challenge'
      '&code_challenge_method=S256',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _errorMessage = DomainConstants.errOAuthNoLaunch;
      notifyListeners();
    }
  }

  Future<void> _handleLxnsOAuth(String code, {int gameType = 0}) async {
    if (_pkceVerifier == null) {
      _errorMessage = DomainConstants.errOAuthNoVerifier;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.exchangeLxnsCode(code, _pkceVerifier!);
      result.fold(
        (bundle) {
          lxnsToken = bundle.lxnsToken;
          lxnsRefreshToken = bundle.lxnsRefreshToken;
          _isLxnsOAuthDone = true;
          _isLxnsVerified = true;
          _pkceVerifier = null;
          _successMessage = DomainConstants.oauthSuccess;
        },
        (e) {
          _errorMessage = DomainConstants.oauthExchangeFailed;
        },
      );
    } catch (e) {
      debugPrint('[OAuth] Token exchange exception: $e');
      _errorMessage = '[OAuth] 字符交换异常: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleLog(String msg) async {
    if (_trackingGameType == null) return;

    // 拦截 HTML 原始数据，执行手机侧独立解析与上传
    if (msg.contains("[HTML_DATA_SYNC]")) {
      try {
        final rawJson = msg.split("[HTML_DATA_SYNC]")[1];
        final payload = jsonDecode(rawJson);
        final html = payload['html'] as String;
        final token = payload['token'] as String;
        final diff = payload['diff'] as int;
        final gameType = payload['gameType'] as int;

        if (gameType == 0) {
          final records = _htmlParser.parse(html);
          if (records.isNotEmpty) {
            final result = await _transferRepo.uploadMaimaiRecords(token, records);
            final label = (diff == 10) ? DomainConstants.diffLabelUtage : "难度$diff";
            result.fold(
              (_) {
                appendLog(
                  "${DomainConstants.logTagUpload} ${DomainConstants.logUploadSuccess.replaceAll("{0}", DomainConstants.modeDivingFish).replaceAll("{1}", label)}",
                );
              },
              (e) {
                appendLog(
                  "${DomainConstants.logTagError} ${DomainConstants.logErrUpload.replaceAll("{0}", DomainConstants.modeDivingFish).replaceAll("{1}", label).replaceAll("{2}", "400").replaceAll("{3}", e.message)}",
                );
              },
            );
          }
          // 重要：反馈给原生侧，解除同步锁，允许切换至落雪平台
          await _vpnRepo.notifyDivingFishTaskDone();
        }
      } catch (e) {
        appendLog("${DomainConstants.logTagError} ${DomainConstants.logErrParse}: $e");
        await _vpnRepo.notifyDivingFishTaskDone();
      }
      return;
    }

    // 同时输出到 IDE 调试控制台
    debugPrint(msg);
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

  Future<void> startVpn({required int mode}) async {
    final finalDfToken = (mode == 0 || mode == 1) ? dfToken : "";
    final finalLxnsToken = (mode == 2 || mode == 1) ? lxnsToken : "";

    final gameType = _trackingGameType ?? 0;
    final gameConfig = _env.getTransferConfig(gameType);

    final String fullLxnsUploadUrl =
        "${_env.lxnsBaseUrl}/${gameConfig.lxnsUploadPath}";
    final String fullDfUploadUrl =
        "${_env.divingFishBaseUrl}/${gameConfig.dfUploadPath}";
    final String fullWahlapAuthUrl =
        "${_env.wahlapAuthBaseUrl}${gameConfig.wahlapAuthLabel}";
    final String wahlapBaseUrl = gameConfig.wahlapBase;

    final Map<int, String> fetchUrlMap = {};
    if (gameType == 0) {
      fetchUrlMap[-1] = "${wahlapBaseUrl}friend/userFriendCode/";
      fetchUrlMap[-2] = "${wahlapBaseUrl}record/";
      fetchUrlMap[10] =
          "${wahlapBaseUrl}record/musicGenre/search/?genre=99&diff=10";
      for (var d in _currentDifficulties) {
        if (d >= 0 && d != 10) {
          fetchUrlMap[d] =
              "${wahlapBaseUrl}record/musicSort/search/?search=V&sort=1&playCheck=on&diff=$d";
        }
      }
    } else {
      fetchUrlMap[-1] = "${wahlapBaseUrl}home/playerData";
      fetchUrlMap[-2] = "${wahlapBaseUrl}record/playlog";
      fetchUrlMap[5] = "${wahlapBaseUrl}record/worldsEndList";
      fetchUrlMap[10] = "${wahlapBaseUrl}record/worldsEndList";
      for (var d in _currentDifficulties) {
        if (d >= 0 && d < 5) {
          fetchUrlMap[d] = "${wahlapBaseUrl}record/musicGenre?difficulty=$d";
        }
      }
    }

    final List<String> genreList = gameConfig.genreList;

    final config = VpnStartConfig(
      dfToken: finalDfToken,
      lxnsToken: finalLxnsToken,
      lxnsUploadUrl: fullLxnsUploadUrl,
      dfUploadUrl: fullDfUploadUrl,
      wahlapBaseUrl: wahlapBaseUrl,
      wahlapAuthUrl: fullWahlapAuthUrl,
      genreList: genreList,
      fetchUrlMap: fetchUrlMap,
      gameTypeIndex: _trackingGameType,
      difficulties: _currentDifficulties.toList(),
    );

    await _vpnRepo.prepareAndStart(config);
    if (_pendingWechat) {
      _pendingWechat = false;
      await _afterVpnReady();
    }
  }

  /// VPN 实际启动后执行：写剪贴板、跳微信、打印日志。
  /// 由 startVpn 在两条路径（直接授权 / onVpnPrepared 回调）收口调用。
  Future<void> _afterVpnReady() async {
    final randomStr = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .substring(0, 8);
    final localProxyUrl = "${_env.proxyBaseUrl}/$randomStr";
    await Clipboard.setData(ClipboardData(text: localProxyUrl));

    final wxUrl = Uri.parse("weixin://");
    if (await canLaunchUrl(wxUrl)) {
      await launchUrl(wxUrl, mode: LaunchMode.externalApplication);
    }

    appendLog("${DomainConstants.logTagVpn} ${DomainConstants.logVpnStarted}");
    appendLog("${DomainConstants.logTagClipboard} ${DomainConstants.logClipReady}");
    appendLog(DomainConstants.logWaitLink);
  }

  Future<bool> stopVpn({
    bool resetState = true,
    bool isManually = false,
  }) async {
    if (isManually) {
      appendLog("${DomainConstants.logTagSystem} ${DomainConstants.logSysTerminated}");
    }
    await _vpnRepo.stop();
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
    _currentDifficulties = difficulties;
    _gameLogs[gameType] = "";
    notifyListeners();

    appendLog("${DomainConstants.logTagSystem} ${DomainConstants.logSysStart}");
    appendLog("${DomainConstants.logTagVpn} ${DomainConstants.logVpnStarting}");

    try {
      _pendingWechat = true;
      await startVpn(mode: mode);
      // 到这里有两种情况：
      // 1. 已有 VPN 权限 → startVpn 内部已调用 _afterVpnReady，_pendingWechat=false
      // 2. 首次需要授权 → 系统弹窗未关闭，_pendingWechat 保持 true；
      //    用户点击允许后 onVpnPrepared 触发 startVpn()，届时再执行 _afterVpnReady
    } catch (e) {
      _pendingWechat = false;
      appendLog(
        "${DomainConstants.logTagError} ${DomainConstants.logErrVpnStart.replaceAll("{0}", e.toString())}",
      );
    }
  }

  @override
  void dispose() {
    _logNotifyTimer?.cancel();
    _linkSubscription?.cancel();
    _statusSubscription?.cancel();
    _logSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTokens() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final bundle = await _authRepo.loadTokenBundle();

    if (bundle.dfToken.isNotEmpty) {
      dfToken = bundle.dfToken;
      for (final gt in [0, 1]) {
        _isDivingFishVerifiedMap[gt] = true;
      }
    }
    if (bundle.lxnsToken.isNotEmpty) {
      lxnsToken = bundle.lxnsToken;
      _isLxnsVerified = true;
    }
    if (bundle.lxnsRefreshToken != null && bundle.lxnsRefreshToken!.isNotEmpty) {
      lxnsRefreshToken = bundle.lxnsRefreshToken;
    }

    if (bundle.canRefresh) {
      final result = await _authRepo.refreshLxnsToken(bundle.lxnsRefreshToken!);
      result.fold(
        (newBundle) {
          lxnsToken = newBundle.lxnsToken;
          lxnsRefreshToken = newBundle.lxnsRefreshToken;
          _isLxnsVerified = true;
          _isLxnsOAuthDone = true;
        },
        (_) {},
      );
    }

    _isStorageLoaded = true;
    notifyListeners();
  }

  void resetVerification({int? gameType, bool df = false, bool lxns = false}) {
    if (df) _isDivingFishVerifiedMap[gameType ?? _activeGameType] = false;
    if (lxns) _isLxnsVerified = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void updateTokens({int? gameType, String? df, String? lxns}) {
    if (df != null) {
      dfToken = df;
      for (final gt in [0, 1]) {
        _isDivingFishVerifiedMap[gt] = false;
      }
    }
    if (lxns != null) {
      lxnsToken = lxns;
      _isLxnsVerified = false;
      _isLxnsOAuthDone = false;
      _authRepo.saveTokenBundle(TokenBundle(
        dfToken: dfToken,
        lxnsToken: lxns,
        lxnsRefreshToken: lxnsRefreshToken,
      ));
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
      _errorMessage = DomainConstants.inputDivingFishToken;
      _isLoading = false;
      notifyListeners();
      return false;
    }
    if (needsLxns && lxnsToken.isEmpty) {
      _errorMessage = DomainConstants.inputLxnsToken;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final game = gameType == 1 ? GameType.chunithm : GameType.maimai;
    bool dfSuccess = _isDivingFishVerifiedMap[gameType] ?? false;
    bool lxnsSuccess = _isLxnsVerified;

    if (needsDf && !dfSuccess) {
      final r = await _authRepo.validateDivingFishToken(dfToken);
      if (r.isFailure) {
        _errorMessage =
            "${DomainConstants.modeDivingFish} ${DomainConstants.logTagAuth} 验证失败";
        _isLoading = false;
        notifyListeners();
        return false;
      }
      dfSuccess = true;
    }
    if (needsLxns && !lxnsSuccess) {
      final r = await _authRepo.validateLxnsToken(lxnsToken, game);
      if (r.isFailure) {
        _errorMessage = "${DomainConstants.modeLxns} ${DomainConstants.logTagAuth} 验证失败";
        _isLoading = false;
        notifyListeners();
        return false;
      }
      lxnsSuccess = true;
    }

    _isDivingFishVerifiedMap[gameType] = dfSuccess;
    _isLxnsVerified = lxnsSuccess;

    await _authRepo.saveTokenBundle(TokenBundle(
      dfToken: dfToken,
      lxnsToken: lxnsToken,
      lxnsRefreshToken: lxnsRefreshToken,
    ));

    _successMessage = DomainConstants.verifySuccess;
    _isLoading = false;
    notifyListeners();
    return true;
  }
}
