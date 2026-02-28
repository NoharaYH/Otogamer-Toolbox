import 'package:flutter/material.dart';
import '../../../design_system/constants/assets.dart';
import '../../../design_system/visual_skins/implementations/maimai_dx/circle_background.dart';
import 'score_sync_logo_wrapper.dart';
import 'score_sync_assembly.dart';

class MaiSyncPage extends StatelessWidget {
  final int mode;
  final ValueChanged<int> onModeChanged;

  const MaiSyncPage({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ScoreSyncLogoWrapper(
      logoPath: AppAssets.logoMaimai,
      subtitle: 'MaiMai DX Prober',
      themeColor: const MaimaiSkin().medium,
      child: Theme(
        data: Theme.of(context).copyWith(extensions: [const MaimaiSkin()]),
        child: ScoreSyncAssembly(
          key: const ValueKey('ScoreSyncAssembly_Mai'),
          mode: mode,
          onModeChanged: onModeChanged,
          gameType: 0,
        ),
      ),
    );
  }
}
