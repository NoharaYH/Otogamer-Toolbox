import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/shared/game_provider.dart';
import '../../design_system/kit_shared/game_page_item.dart';
import '../../design_system/kit_shared/kit_game_carousel.dart';

// Contents
import 'components/mai_sync_page.dart';
import 'components/chu_sync_page.dart';

// Skins
import '../../design_system/visual_skins/implementations/maimai_dx/circle_background.dart';
import '../../design_system/visual_skins/implementations/chunithm/verse_background.dart';

class ScoreSyncPage extends StatefulWidget {
  const ScoreSyncPage({super.key});

  @override
  State<ScoreSyncPage> createState() => _ScoreSyncPageState();
}

class _ScoreSyncPageState extends State<ScoreSyncPage>
    with WidgetsBindingObserver {
  late final PageController _localController;
  bool _initialized = false;

  // 按 gameType 缓存模式选择（0=水鱼, 1=双平台, 2=落雪），防止游戏切换时重置
  final Map<int, int> _transferModes = {0: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final gameProvider = context.read<GameProvider>();
    _localController = PageController(initialPage: gameProvider.currentIndex);

    if (!_initialized) {
      _initialized = true;
      gameProvider.init().then((_) {
        if (mounted && _localController.hasClients) {
          _localController.jumpToPage(gameProvider.currentIndex);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        gameProvider.pageValueNotifier.value = _localController.initialPage
            .toDouble();
      }
    });

    _localController.addListener(() {
      if (_localController.hasClients && _localController.page != null) {
        gameProvider.pageValueNotifier.value = _localController.page!;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      context.read<GameProvider>().saveExitPage();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();

    return KitGameCarousel(
      controller: _localController,
      onPageChanged: gameProvider.onPageChanged,
      items: [
        GamePageItem(
          skin: const MaimaiSkin(),
          content: MaiSyncPage(
            mode: _transferModes[0]!,
            onModeChanged: (val) => setState(() => _transferModes[0] = val),
          ),
          title: 'Maimai DX',
        ),
        GamePageItem(
          skin: const ChunithmSkin(),
          content: ChuSyncPage(
            mode: _transferModes[1]!,
            onModeChanged: (val) => setState(() => _transferModes[1] = val),
          ),
          title: 'Chunithm',
        ),
      ],
    );
  }
}
