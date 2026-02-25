import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../../kernel/services/storage_service.dart';
import '../../kernel/services/api_service.dart';
import '../../score_sync/wechat_crawler.dart';

@injectable
class TransferProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  late final WechatCrawler _crawler;

  // Controllers for input fields
  final TextEditingController dfController = TextEditingController();
  final TextEditingController lxnsController = TextEditingController();

  // Observable State
  bool _isLoading = false;
  bool _isStorageLoaded = false;
  bool _isDivingFishVerified = false;
  bool _isLxnsVerified = false;
  bool _isVpnRunning = false;
  Set<int> _selectedDifficulties = {0, 1, 2, 3, 4, 5};
  bool _isTracking = false;
  int? _trackingGameType;
  String? _errorMessage;
  String? _successMessage;
  String _vpnLog = "";

  static const _channel = MethodChannel('com.nohara.otogamer/vpn');

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
  String get vpnLog => _vpnLog;

  Timer? _logNotifyTimer;

  TransferProvider(this._apiService, this._storageService) {
    _crawler = WechatCrawler(
      onLog: (msg) => _handleLog(msg),
      onError: (err) => _handleLog("[ERROR] $err"),
    );
    _loadTokens();
    _initChannel();
  }

  void _handleLog(String msg) {
    _vpnLog += "$msg\n";
    // Debounce notifyListeners to avoid ANR during high-frequency logging
    if (_logNotifyTimer?.isActive ?? false) return;
    _logNotifyTimer = Timer(const Duration(milliseconds: 100), () {
      notifyListeners();
    });
  }

  void _initChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onStatusChanged':
          _isVpnRunning = call.arguments['isRunning'];
          final status = call.arguments['status'] as String?;
          if (status != null) _successMessage = status;
          notifyListeners();
          break;
        case 'onLogReceived':
          _vpnLog += "${call.arguments}\n";
          notifyListeners();
          break;
        case 'onAuthUrlReceived':
          final url = call.arguments as String;
          _vpnLog += "[SYSTEM] 授权链接已捕获，正在后台启动传分任务...\n";
          notifyListeners();

          _crawler
              .executeSync(
                username: dfController.text.trim(),
                password: "",
                difficulties: _selectedDifficulties,
                wechatAuthUrl: url,
              )
              .whenComplete(() {
                _vpnLog += "[SYSTEM] 传分全流程结束，已断开代理。您可以手动关闭日志面板。\n";
                stopVpn(resetState: false);
              });
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
      await _channel.invokeMethod('startVpn', {
        'username': dfController.text,
        'password': lxnsController.text,
      });
    }
  }

  Future<bool> stopVpn({bool resetState = true}) async {
    await _channel.invokeMethod('stopVpn');
    if (resetState) {
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
    _selectedDifficulties = difficulties;
    _vpnLog = "[SYSTEM] 正在启动本地代理环境...\n";
    notifyListeners();

    try {
      await startVpn();

      // Use local proxy URL with random path to bypass WeChat cache
      final randomStr = DateTime.now().millisecondsSinceEpoch
          .toRadixString(36)
          .substring(0, 8);
      final localProxyUrl = "http://127.0.0.2:8284/$randomStr";
      await Clipboard.setData(ClipboardData(text: localProxyUrl));

      _vpnLog += "[VPN] 服务已启动，正在监听网络包\n";
      _vpnLog += "[CLIPBOARD] 本地中转链接已复制，请前往微信打开\n";
      _vpnLog += "[HINT] 捕获授权码后，同步将在后台自动完成\n";
    } catch (e) {
      _vpnLog += "[ERROR] 初始化失败: $e\n";
    }

    notifyListeners();
  }

  @override
  void dispose() {
    dfController.dispose();
    lxnsController.dispose();
    super.dispose();
  }

  Future<void> _loadTokens() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final df = await _storageService.read(StorageService.kDivingFishToken);
    final lxns = await _storageService.read(StorageService.kLxnsToken);

    if (df != null && df.isNotEmpty) {
      dfController.text = df;
      _isDivingFishVerified = true;
    }
    if (lxns != null && lxns.isNotEmpty) {
      lxnsController.text = lxns;
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

  void handlePaste(String text, {required bool isDf}) {
    if (isDf) {
      dfController.text = text;
      _isDivingFishVerified = false;
    } else {
      lxnsController.text = text;
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

    if (needsDf && dfController.text.isEmpty) {
      _errorMessage = "请输入水鱼 Token";
      _isLoading = false;
      notifyListeners();
      return false;
    }
    if (needsLxns && lxnsController.text.isEmpty) {
      _errorMessage = "请输入落雪 Token";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      bool dfSuccess = _isDivingFishVerified;
      bool lxnsSuccess = _isLxnsVerified;

      if (needsDf && !dfSuccess) {
        dfSuccess = await _apiService.validateDivingFishToken(
          dfController.text,
        );
        if (!dfSuccess) {
          _errorMessage = "水鱼 Token 验证失败";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      if (needsLxns && !lxnsSuccess) {
        lxnsSuccess = await _apiService.validateLxnsToken(lxnsController.text);
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
        await _storageService.save(
          StorageService.kDivingFishToken,
          dfController.text,
        );
      }
      if (lxnsSuccess) {
        await _storageService.save(
          StorageService.kLxnsToken,
          lxnsController.text,
        );
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
