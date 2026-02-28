import 'package:flutter/material.dart';
import '../../../design_system/constants/assets.dart';
import '../../../design_system/visual_skins/implementations/chunithm/verse_background.dart';
import 'score_sync_logo_wrapper.dart';
import 'score_sync_assembly.dart';

class ChuSyncPage extends StatelessWidget {
  final int mode;
  final ValueChanged<int> onModeChanged;

  const ChuSyncPage({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ScoreSyncLogoWrapper(
      logoPath: AppAssets.logoChunithm,
      subtitle: 'CHUNITHM Prober',
      themeColor: const ChunithmSkin().medium,
      child: Theme(
        data: Theme.of(context).copyWith(extensions: [const ChunithmSkin()]),
        child: ScoreSyncAssembly(
          key: const ValueKey('ScoreSyncAssembly_Chu'),
          mode: mode,
          onModeChanged: onModeChanged,
          gameType: 1,
        ),
      ),
    );
  }
}
