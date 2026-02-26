import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../../kernel/services/storage_service.dart';
import '../../kernel/services/api_service.dart';

/// TransferProvider：纯 UI 状态中转层。
///
/// 传分的核心业务逻辑（WechatCrawler、Cookie管理、数据抓取）
/// 已全量迁移至 Android 原生侧（CrawlerCaller.java + WechatCrawler.java）。
/// 本类职责仅为：
///   1. 管理用户输入 (Token 表单)
///   2. 通过 MethodChannel 向原生层下发指令
///   3. 接收原生层推送的日志流并提供给 UI 消费
@injectable
class TransferProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  // 数据状态
  String dfToken = '';
  String lxnsToken = '';

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
          if (status == '传分完成' || (status == null && !_isVpnRunning)) {
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
        'difficulties': _currentDifficulties.toList(),
      });
    }
  }

  Future<bool> stopVpn({
    bool resetState = true,
    bool isManually = false,
  }) async {
    if (isManually) {
      appendLog("[STOP] 传分业务已终止");
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

    appendLog("[START]传分业务挂起");
    appendLog("[SYSTEM] 正在启动本地代理环境...");

    try {
      await startVpn();

      // 使用随机 Path 防止微信浏览器缓存上一次的重定向
      final randomStr = DateTime.now().millisecondsSinceEpoch
          .toRadixString(36)
          .substring(0, 8);
      final localProxyUrl = "http://127.0.0.2:8284/$randomStr";
      await Clipboard.setData(ClipboardData(text: localProxyUrl));

      appendLog("[VPN] 服务已启动，正在监听网络包");
      appendLog("[CLIPBOARD] 本地中转链接已复制，请前往微信打开");
      appendLog("[HINT] 捕获授权码后，同步将在后台自动完成");
    } catch (e) {
      appendLog("[ERROR] 初始化失败: $e");
    }
  }

  @override
  void dispose() {
    _logNotifyTimer?.cancel();
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
      _errorMessage = "请输入水鱼 Token";
      _isLoading = false;
      notifyListeners();
      return false;
    }
    if (needsLxns && lxnsToken.isEmpty) {
      _errorMessage = "请输入落雪 Token";
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
          _errorMessage = "水鱼 Token 验证失败";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      if (needsLxns && !lxnsSuccess) {
        lxnsSuccess = await _apiService.validateLxnsToken(lxnsToken);
        if (!lxnsSuccess) {
          _errorMessage = "落雪 Token 验证失败";
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

      _successMessage = "验证通过，配置已保存";
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
