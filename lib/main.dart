import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'kernel/di/injection.dart';
import 'ui/pages/score_sync/score_sync_page.dart';
import 'kernel/state/game_provider.dart';
import 'kernel/state/transfer_provider.dart';
import 'kernel/state/toast_provider.dart';
import 'kernel/state/mai_music_provider.dart';
import 'kernel/state/chu_music_provider.dart';

import 'ui/design_system/kit_shared/toast_queue_manager.dart';

void main() {
  configureDependencies();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => getIt<TransferProvider>()),
        ChangeNotifierProvider(create: (_) => ToastProvider()),
        ChangeNotifierProvider(create: (_) => MaiMusicProvider()),
        ChangeNotifierProvider(create: (_) => ChuMusicDataProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaiChuniSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'JiangCheng',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ToastOverlay(child: ScoreSyncPage()),
    );
  }
}
