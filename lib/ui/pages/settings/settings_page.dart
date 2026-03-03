import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/shared/game_provider.dart';
import '../../design_system/constants/colors.dart';
import '../../design_system/constants/animations.dart';
import '../../design_system/kit_shared/kit_staggered_entrance.dart';
import '../../../application/shared/navigation_provider.dart';
import '../../design_system/kit_setting/setting_header.dart';
import '../../design_system/kit_setting/setting_tile.dart';
import 'categories/app_settings_page.dart';
import 'categories/personalization_page.dart';
import 'categories/sync_service_page.dart';
import '../../design_system/theme/core/app_theme.dart';
import '../../design_system/theme/universal_theme/star_trails.dart';
import 'categories/about_page.dart';

/// 设置模块门面容器：Overriding Layer (v4.0)
/// 已重构：移除旧的分页逻辑，采用简洁的垂直卡片式列表。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late NavigationProvider _nav;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // 扩张动效状态
  int? _activeCategoryIndex;
  late AnimationController _expansionController;
  late Animation<double> _expansionAnimation;

  // 即时图层变轨快照 (Layer Swap)
  ui.Image? _currentSnapshot;
  ui.Image? _oldSnapshot;
  late AnimationController _swapController;
  late Animation<double> _swapAnimation;
  int _lastThemeHash = 0;

  final List<({IconData icon, String title, Color color, Widget page})>
  categories = [
    (
      icon: Icons.sync,
      title: "成绩同步设置",
      color: Colors.green,
      page: const SyncServicePage(themeColor: Colors.green),
    ),
    (
      icon: Icons.settings,
      title: "应用设置",
      color: Colors.blue,
      page: const AppSettingsPage(themeColor: Colors.blue),
    ),
    (
      icon: Icons.palette,
      title: "个性化设置",
      color: Colors.purpleAccent,
      page: const PersonalizationPage(themeColor: Colors.purpleAccent),
    ),
    (
      icon: Icons.info_outline,
      color: Colors.grey,
      title: "应用信息",
      page: const AboutPage(themeColor: Colors.grey),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: UiAnimations.standard,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _expansionAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOutQuart,
    );

    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _swapAnimation = CurvedAnimation(
      parent: _swapController,
      curve: Curves.easeOutCubic,
    );

    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nav = context.read<NavigationProvider>();

    // 取消此处对 _nav.bgSnapshot 盲目的吃入并缓存行为，
    // 因为这会干扰真正的新摄制流程状态，只应当从顶栈快照获取一次或让隔离层自动处理。
    if (_currentSnapshot == null && _nav.bgSnapshot != null) {
      _currentSnapshot = _nav.bgSnapshot;
    }

    final gp = context.watch<GameProvider>();
    final newHash = Object.hash(
      gp.isThemeGlobal,
      gp.activeSkinId,
      gp.maiSkinId,
      gp.chuSkinId,
    );

    if (_lastThemeHash == 0) {
      _lastThemeHash = newHash;
    } else if (_lastThemeHash != newHash) {
      _lastThemeHash = newHash;
      _triggerLayerSwap();
    }
  }

  void _triggerLayerSwap() async {
    // [时差修补] 延长 150ms 等待至 200ms
    // 强制挂起快照捕捉，为了给予底层所有的 AnimatedContainer, AnimatedDefaultTextStyle
    // 等隐式动画组件足够的 150ms-200ms 退场和渲染到全新颜色的时间，避免截取出带有旧色残影的断层假象。
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final newImg = await _nav.captureTask?.call();
    if (newImg != null && mounted) {
      _nav.registerTempSnapshot(newImg);
      setState(() {
        _oldSnapshot = _currentSnapshot;
        _currentSnapshot = newImg;
      });
      _swapController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _expansionController.dispose();
    _swapController.dispose();
    // 采用缓存引用清理背景快照，规避 context 停用异常 (Memory GC)
    _nav.clearBgSnapshot();
    super.dispose();
  }

  Widget _buildBlurEngine(ui.Image image) {
    return RepaintBoundary(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: 15.0,
          sigmaY: 15.0,
          tileMode: TileMode.mirror,
        ),
        child: RawImage(
          image: image,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final skinExtension =
        Theme.of(context).extension<AppTheme>() ?? const StarTrailsTheme();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Theme(
        data: Theme.of(context).copyWith(extensions: [skinExtension]),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 1. 物理隔离快照背景 (Snapshot Isolation Layer)
              Positioned.fill(
                child: Consumer<NavigationProvider>(
                  builder: (context, nav, _) {
                    return GestureDetector(
                      onTap: () => _activeCategoryIndex == null
                          ? _handleBack()
                          : _handleCategoryBack(),
                      child: AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, _) => Opacity(
                          opacity: _fadeAnimation.value,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. 底层：新摄制的背景
                              if (_currentSnapshot != null)
                                _buildBlurEngine(_currentSnapshot!),

                              // 2. 表层：被淘汰的老背景，正在做 FadeOut (1 -> 0)
                              if (_oldSnapshot != null)
                                AnimatedBuilder(
                                  animation: _swapAnimation,
                                  builder: (context, _) => Opacity(
                                    opacity: 1.0 - _swapAnimation.value,
                                    child: _buildBlurEngine(_oldSnapshot!),
                                  ),
                                ),

                              // 3. Fallback 或者垫底灰度
                              if (_currentSnapshot == null &&
                                  _oldSnapshot == null)
                                Container(
                                  color: UiColors.white.withValues(alpha: 0.25),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2. 核心内容区 (分段响应动效)
              AnimatedBuilder(
                animation: Listenable.merge([
                  _fadeAnimation,
                  _expansionAnimation,
                ]),
                builder: (context, _) => Column(
                  children: [
                    // 动态 Header 区域 - 向下滑入 (Slide Down)
                    ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: _fadeAnimation.value,
                        child: SizedBox(
                          height: topPadding + 54,
                          child: Stack(
                            children: [
                              // Phase A: "返回首页" Header - 收缩
                              ClipRect(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  heightFactor: 1 - _expansionAnimation.value,
                                  child: Opacity(
                                    opacity:
                                        (1 - _expansionAnimation.value) *
                                        _fadeAnimation.value,
                                    child: SettingHeader(
                                      title: '返回首页',
                                      icon: Icons.home_outlined,
                                      iconColor: Colors.transparent,
                                      onBack: _handleBack,
                                      isSubPage: false,
                                    ),
                                  ),
                                ),
                              ),

                              // Phase B: 二级页 Header - 扩张
                              if (_activeCategoryIndex != null)
                                ClipRect(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    heightFactor: _expansionAnimation.value,
                                    child: SettingHeader(
                                      title: categories[_activeCategoryIndex!]
                                          .title,
                                      icon: categories[_activeCategoryIndex!]
                                          .icon,
                                      iconColor:
                                          categories[_activeCategoryIndex!]
                                              .color,
                                      expansionProgress:
                                          _expansionAnimation.value,
                                      onBack: _handleCategoryBack,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 列表/二级页内容区域 - 向上滑入 (Slide Up 对冲)
                    Expanded(
                      child: Transform.translate(
                        offset: Offset(0, 40 * (1 - _fadeAnimation.value)),
                        child: Stack(
                          children: [
                            // 1. 主列表
                            Opacity(
                              opacity:
                                  (1 - _expansionAnimation.value) *
                                  _fadeAnimation.value,
                              child: IgnorePointer(
                                ignoring: _activeCategoryIndex != null,
                                child: _buildMainList(),
                              ),
                            ),

                            // 2. 二级页内容
                            if (_activeCategoryIndex != null)
                              RepaintBoundary(
                                child: Opacity(
                                  opacity: _expansionAnimation.value,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      40 * (1 - _expansionAnimation.value),
                                    ),
                                    child:
                                        _cachedSubPage ??
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _cachedSubPage;

  void _handleCategoryTap(int index) {
    setState(() {
      _activeCategoryIndex = index;
      _cachedSubPage = _buildThemedSubPage(context);
    });
    _expansionController.forward();
  }

  void _handleCategoryBack() {
    _expansionController.reverse().then((_) {
      setState(() {
        _activeCategoryIndex = null;
        _cachedSubPage = null;
      });
    });
  }

  /// 物理隔离：预构建二级页，隔离 AnimatedBuilder 的高频重绘。
  Widget _buildThemedSubPage(BuildContext context) {
    if (_activeCategoryIndex == null) return const SizedBox.shrink();

    final cat = categories[_activeCategoryIndex!];
    final skin =
        Theme.of(context).extension<AppTheme>() ?? const StarTrailsTheme();

    return Theme(
      key: ValueKey('themed_page_${_activeCategoryIndex}'),
      data: Theme.of(
        context,
      ).copyWith(extensions: [skin.copyWith(medium: cat.color)]),
      child: cat.page,
    );
  }

  Widget _buildMainList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: List.generate(categories.length, (index) {
          final cat = categories[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: KitStaggeredEntrance(
              index: index + 1,
              child: SettingTile(
                icon: cat.icon,
                title: cat.title,
                iconColor: cat.color,
                onTap: () => _handleCategoryTap(index),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _handleBack() {
    if (_activeCategoryIndex != null) {
      _handleCategoryBack();
      return;
    }
    _fadeController.reverse().then((_) {
      context.read<NavigationProvider>().closeSettings();
    });
  }
}
