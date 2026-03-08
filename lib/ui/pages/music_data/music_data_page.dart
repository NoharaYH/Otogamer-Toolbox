import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/mai/mai_music_provider.dart';

import '../../../application/shared/game_provider.dart';

import '../../design_system/constants/assets.dart';

import '../../design_system/kit_shared/kit_game_carousel.dart';
import '../../design_system/kit_shared/game_page_item.dart';
import '../../design_system/theme/theme_catalog.dart';
import '../../design_system/theme/special_theme/utage.dart';

import '../score_sync/components/score_sync_logo_wrapper.dart';

import 'components/mai_music_assembly.dart';
import 'components/chu_music_assembly.dart';

class MusicDataPage extends StatefulWidget {
  const MusicDataPage({super.key});

  @override
  State<MusicDataPage> createState() => _MusicDataPageState();
}

class _MusicDataPageState extends State<MusicDataPage> {
  late final PageController _localController;

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

    gameProvider.addListener(_syncControllerToCurrentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MaiMusicProvider>();
      await provider.init();
    });
  }

  void _syncControllerToCurrentIndex() {
    final gp = context.read<GameProvider>();
    if (!mounted || !_localController.hasClients) return;
    final p = _localController.page;
    if (p == null) return;
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
    final maiMusicProvider = context.watch<MaiMusicProvider>();
    final gameProvider = context.watch<GameProvider>();

    final maiSkinId = gameProvider.isThemeGlobal
        ? gameProvider.activeSkinId
        : gameProvider.maiSkinId;
    final chuSkinId = gameProvider.isThemeGlobal
        ? gameProvider.activeSkinId
        : gameProvider.chuSkinId;

    final maiSkin = maiMusicProvider.isUtageMode
        ? const UtageTheme()
        : gameProvider.resolvedTheme(ThemeCatalog.findThemeById(maiSkinId));
    final chuSkin = gameProvider.resolvedTheme(
      ThemeCatalog.findThemeById(chuSkinId),
    );

    return KitGameCarousel(
      controller: _localController,
      onPageChanged: (index) {
        // 同步回全局索引，确保切回同步页时状态一致
        gameProvider.setIndex(index);
      },
      items: [
        GamePageItem(
          skin: maiSkin,
          title: 'Maimai DX',
          content: ScoreSyncLogoWrapper(
            logoPath: maiMusicProvider.isUtageMode
                ? AppAssets.logoUtage
                : (maiSkin.themeId == 'mai_dx'
                      ? AppAssets.logoMaimaiDx
                      : AppAssets.logoMaimai),
            subtitle: maiMusicProvider.isUtageMode
                ? 'UTAGE LIBRARY'
                : 'MUSIC LIBRARY',
            themeColor: maiSkin.basic,
            child: const MaiMusicAssembly(),
          ),
        ),
        GamePageItem(
          skin: chuSkin,
          title: 'Chunithm',
          content: ScoreSyncLogoWrapper(
            logoPath: AppAssets.logoChunithm,
            subtitle: 'MUSIC LIBRARY',
            themeColor: chuSkin.basic,
            child: const ChuMusicAssembly(),
          ),
        ),
      ],
    );
  }
}
