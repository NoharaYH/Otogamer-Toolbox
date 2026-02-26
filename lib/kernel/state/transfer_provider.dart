import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

@injectable
class TransferProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  // Controllers for input fields
  final TextEditingController dfController = TextEditingController();
  final TextEditingController lxnsController = TextEditingController();

  // Observable State
  bool _isLoading = false;
  bool _isStorageLoaded = false;
  bool _isDivingFishVerified = false;
  bool _isLxnsVerified = false;
  bool _isVpnRunning = false;
  bool _isTracking = false;
  String? _errorMessage;
  String? _successMessage;
  String _vpnLog = "";

  static const _channel = MethodChannel('com.noharayh.otokit/vpn');

  // Getters
  bool get isLoading => _isLoading;
  bool get isStorageLoaded => _isStorageLoaded;
  bool get isDivingFishVerified => _isDivingFishVerified;
  bool get isLxnsVerified => _isLxnsVerified;
  bool get isVpnRunning => _isVpnRunning;
  bool get isTracking => _isTracking;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get vpnLog => _vpnLog;

  // Mode Selection (0: DF, 1: Both, 2: LXNS)
  // We can manage mode per game type here or let UI pass it in.
  // For simplicity, let's keep mode in UI for now or separate it if it becomes complex.

  TransferProvider(this._apiService, this._storageService) {
    _loadTokens();
    _initChannel();
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
        'password':
            lxnsController.text, // Mapping lxns token as second param if needed
      });
    }
  }

  Future<void> stopVpn() async {
    await _channel.invokeMethod('stopVpn');
    _isTracking = false;
    notifyListeners();
  }

  void startTracking() {
    _isTracking = true;
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    notifyListeners();
  }

  Future<void> startImport() async {
    // 1. 启动 VPN
    await startVpn();

    // 2. 复制链接 (模拟获取授权链接，实际可能由 native 或 API 提供)
    // 根据 DataContext.HookHost 逻辑，这里模拟一个
    const authUrl = "http://maimai.com.cn/auth";
    await Clipboard.setData(const ClipboardData(text: authUrl));

    // 3. 开启跟踪模式并初始化日志
    _isTracking = true;
    _vpnLog = "[SYSTEM] 开始准备环境...\n";
    _vpnLog += "[VPN] 服务已启动，正在监听网络包\n";
    _vpnLog += "[CLIPBOARD] 授权链接已复制，请前往微信访问\n";

    notifyListeners();
  }

  @override
  void dispose() {
    dfController.dispose();
    lxnsController.dispose();
    super.dispose();
  }

  Future<void> _loadTokens() async {
    // Artificial delay to ensure the UI has time to render the initial "collapsed" state
    // and then play the expansion animation.
    await Future.delayed(const Duration(milliseconds: 300));

    final df = await _storageService.read(StorageService.kDivingFishToken);
    final lxns = await _storageService.read(StorageService.kLxnsToken);

    if (df != null && df.isNotEmpty) {
      dfController.text = df;
      // Pre-assume verified if loaded from storage to improve UX
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

  void resetAllVerification() {
    _isDivingFishVerified = false;
    _isLxnsVerified = false;
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

  // Core Business Logic: Verify and Save
  Future<bool> verifyAndSave({required int mode}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    // 强制最小加载时间 (500ms)，确保 loading 动画能被肉眼捕捉，提供良好反馈
    await Future.delayed(const Duration(milliseconds: 500));

    final needsDf = mode == 0 || mode == 1;
    final needsLxns = mode == 2 || mode == 1;

    // 1. Local Validation
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

      // 2. Remote Verification (DF)
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

      // 3. Remote Verification (LXNS)
      if (needsLxns && !lxnsSuccess) {
        lxnsSuccess = await _apiService.validateLxnsToken(lxnsController.text);
        if (!lxnsSuccess) {
          _errorMessage = "落雪 Token 验证失败";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // 4. Persistence
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
