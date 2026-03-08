import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/shared/game_provider.dart';
import '../../design_system/kit_shared/game_page_item.dart';
import '../../design_system/kit_shared/kit_game_carousel.dart';
import '../../design_system/theme/theme_catalog.dart';

// Contents
import 'components/mai_sync_page.dart';
import 'components/chu_sync_page.dart';

// Skins

class ScoreSyncPage extends StatefulWidget {
  const ScoreSyncPage({super.key});

  @override
  State<ScoreSyncPage> createState() => _ScoreSyncPageState();
}

class _ScoreSyncPageState extends State<ScoreSyncPage> {
  late final PageController _localController;

  // 按 gameIndex 缓存游戏内配置（防止切换页面时重置）
  // transferMode: 0=水鱼, 1=双平台, 2=落雪
  final Map<int, int> _transferModes = {0: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    final gameProvider = context.read<GameProvider>();
    _localController = PageController(initialPage: gameProvider.currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        gameProvider.pageValueNotifier.value =
            _localController.initialPage.toDouble();
      }
    });

    _localController.addListener(() {
      if (_localController.hasClients && _localController.page != null) {
        gameProvider.pageValueNotifier.value = _localController.page!;
      }
    });

    // init 异步完成后 currentIndex 可能已变，同步 PageController 以避免背景错位
    gameProvider.addListener(_syncControllerToCurrentIndex);
  }

  void _syncControllerToCurrentIndex() {
    final gp = context.read<GameProvider>();
    if (!mounted || !_localController.hasClients) return;
    final p = _localController.page;
    if (p == null) return;
    // 仅在页面稳定（非滑动中）时同步，避免打断用户滑动
    final isStable = (p - p.round()).abs() < 0.01;
    if (!isStable) return;
    if (p.round() != gp.currentIndex) {
      _localController.jumpToPage(gp.currentIndex);
    }
  }

  @override
  void dispose() {
    context.read<GameProvider>().removeListener(_syncControllerToCurrentIndex);
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();

    final maiSkinId = gameProvider.isThemeGlobal
        ? gameProvider.activeSkinId
        : gameProvider.maiSkinId;
    final chuSkinId = gameProvider.isThemeGlobal
        ? gameProvider.activeSkinId
        : gameProvider.chuSkinId;

    final maiSkin = gameProvider.resolvedTheme(
      ThemeCatalog.findThemeById(maiSkinId),
    );
    final chuSkin = gameProvider.resolvedTheme(
      ThemeCatalog.findThemeById(chuSkinId),
    );

    return KitGameCarousel(
      controller: _localController,
      onPageChanged: gameProvider.onPageChanged,
      items: [
        GamePageItem(
          skin: maiSkin,
          content: MaiSyncPage(
            mode: _transferModes[0]!,
            onModeChanged: (val) {
              setState(() => _transferModes[0] = val);
              context.read<GameProvider>().updateActiveContext(
                game: 'Mai',
                service: _serviceLabel(val),
              );
            },
          ),
          title: 'Maimai DX',
        ),
        GamePageItem(
          skin: chuSkin,
          content: ChuSyncPage(
            mode: _transferModes[1]!,
            onModeChanged: (val) {
              setState(() => _transferModes[1] = val);
              context.read<GameProvider>().updateActiveContext(
                game: 'Chu',
                service: _serviceLabel(val),
              );
            },
          ),
          title: 'Chunithm',
        ),
      ],
    );
  }

  /// 模式索引转化为存储字符串（与 Provider payload 对齐）
  static String _serviceLabel(int mode) {
    switch (mode) {
      case 1:
        return 'Dual';
      case 2:
        return 'LuoXue';
      default:
        return 'DivingFish';
    }
  }
}
