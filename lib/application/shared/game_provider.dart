import 'package:flutter/material.dart';
import '../../kernel/services/storage_service.dart';
import '../../kernel/di/injection.dart';

/// 启动页偏好枚举
enum StartupPagePref { mai, chu, last }

class GameProvider extends ChangeNotifier {
  int _currentIndex = 0;
  final ValueNotifier<double> pageValueNotifier = ValueNotifier<double>(0.0);

  int get currentIndex => _currentIndex;

  StartupPagePref _startupPref = StartupPagePref.mai;
  StartupPagePref get startupPref => _startupPref;

  /// 初始化：读取启动页偏好并应用
  Future<void> init() async {
    final storage = getIt<StorageService>();
    final prefStr = await storage.read(StorageService.kStartupPage);
    final lastStr = await storage.read(StorageService.kLastExitPage);

    _startupPref = _parsePref(prefStr);

    int initialIndex = 0;
    switch (_startupPref) {
      case StartupPagePref.chu:
        initialIndex = 1;
        break;
      case StartupPagePref.last:
        initialIndex = int.tryParse(lastStr ?? '0') ?? 0;
        break;
      case StartupPagePref.mai:
        initialIndex = 0;
        break;
    }

    _currentIndex = initialIndex.clamp(0, 1);
    pageValueNotifier.value = _currentIndex.toDouble();
    notifyListeners();
  }

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index.clamp(0, 1);
      notifyListeners();
    }
  }

  // Update index from PageView scroll
  void onPageChanged(int index) {
    setIndex(index);
  }

  /// 在 App 退出/挂起时调用，持久化当前页面索引
  Future<void> saveExitPage() async {
    await getIt<StorageService>().save(
      StorageService.kLastExitPage,
      _currentIndex.toString(),
    );
  }

  /// 更新启动页偏好并持久化
  Future<void> setStartupPref(StartupPagePref pref) async {
    if (_startupPref == pref) return;
    _startupPref = pref;
    await getIt<StorageService>().save(
      StorageService.kStartupPage,
      _prefToString(pref),
    );
    notifyListeners();
  }

  static StartupPagePref _parsePref(String? value) {
    switch (value) {
      case 'chu':
        return StartupPagePref.chu;
      case 'last':
        return StartupPagePref.last;
      default:
        return StartupPagePref.mai;
    }
  }

  static String _prefToString(StartupPagePref pref) {
    switch (pref) {
      case StartupPagePref.chu:
        return 'chu';
      case StartupPagePref.last:
        return 'last';
      case StartupPagePref.mai:
        return 'mai';
    }
  }

  @override
  void dispose() {
    pageValueNotifier.dispose();
    super.dispose();
  }
}
