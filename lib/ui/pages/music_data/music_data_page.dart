import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../kernel/state/mai_music_provider.dart';
import '../../../kernel/state/toast_provider.dart';
import '../../design_system/page_shell.dart';
import '../../design_system/constants/sizes.dart';
import '../../design_system/kit_shared/confirm_button.dart';

class MusicDataPage extends StatefulWidget {
  const MusicDataPage({super.key});

  @override
  State<MusicDataPage> createState() => _MusicDataPageState();
}

class _MusicDataPageState extends State<MusicDataPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载后检查数据状态
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MaiMusicProvider>();
      await provider.init();

      if (!provider.hasData && mounted) {
        _showSyncPrompt(context);
      }
    });
  }

  void _showSyncPrompt(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(UiSizes.cardBorderRadius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.library_music_outlined,
                  size: 48,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  '曲库尚未初始化',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  '当前本地没有曲目数据，为了获得完整的查询体验，请手动执行一次同步拉取。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 24),
                ConfirmButton(
                  text: '立即同步',
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final provider = context.read<MaiMusicProvider>();
                    final toast = context.read<ToastProvider>();

                    toast.show('正在拉取并精炼数据...', ToastType.verifying);
                    try {
                      await provider.sync();
                      toast.show('同步成功！', ToastType.confirmed);
                    } catch (e) {
                      toast.show('同步失败：$e', ToastType.error);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '稍后再说',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      child: Consumer<MaiMusicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!provider.hasData) {
            return const Center(child: Text('暂无曲目，请点击同步按钮拉取数据'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
            itemCount: provider.musics.length,
            itemBuilder: (context, index) {
              final music = provider.musics[index];
              return Card(
                child: ListTile(
                  title: Text(music.basicInfo.title),
                  subtitle: Text(music.basicInfo.artist),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
