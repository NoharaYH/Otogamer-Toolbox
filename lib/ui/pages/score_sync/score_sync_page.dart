import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../kernel/state/game_provider.dart';
import '../../design_system/kit_shared/game_page_item.dart';
import '../../design_system/kit_shared/kit_game_carousel.dart';

// Contents
import 'components/mai_sync_page.dart';
import 'components/chu_sync_page.dart';

// Skins
import '../../design_system/visual_skins/implementations/maimai_dx/circle_background.dart';
import '../../design_system/visual_skins/implementations/chunithm/verse_background.dart';

import '../settings/settings_page.dart';
import '../music_data/music_data_page.dart';

class ScoreSyncPage extends StatelessWidget {
  const ScoreSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();

    return KitGameCarousel(
      controller: gameProvider.pageController,
      onPageChanged: gameProvider.onPageChanged,
      items: [
        const GamePageItem(
          skin: MaimaiSkin(),
          content: MaiSyncPage(),
          title: 'Maimai DX',
        ),
        const GamePageItem(
          skin: ChunithmSkin(),
          content: ChuSyncPage(),
          title: 'Chunithm',
        ),
      ],
      headerActions: [
        IconButton(
          icon: const Icon(Icons.library_music, color: Colors.black87),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MusicDataPage()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black87),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
      ],
    );
  }
}
