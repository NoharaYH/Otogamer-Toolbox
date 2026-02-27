import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../logic/mai_music_data/data_sync/mai_sync_handler.dart';
import '../visual_skins/skin_extension.dart';
import '../constants/sizes.dart';
import '../kit_shared/confirm_button.dart';

class KitMusicSyncPrompt extends StatefulWidget {
  final SyncPhase phase;
  final int current;
  final int total;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const KitMusicSyncPrompt({
    super.key,
    required this.phase,
    required this.current,
    required this.total,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<KitMusicSyncPrompt> createState() => _KitMusicSyncPromptState();
}

class _KitMusicSyncPromptState extends State<KitMusicSyncPrompt> {
  bool _isVisible = true;
  bool _hasStarted = false;
  int _dotCount = 1;
  Timer? _dotTimer;

  bool _isTyping = false;
  String _typedText = '';

  @override
  void initState() {
    super.initState();
    _startDotTimer();
  }

  void _startDotTimer() {
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      setState(() {
        _dotCount = (_dotCount % 3) + 1;
      });
    });
  }

  @override
  void didUpdateWidget(KitMusicSyncPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasStarted && widget.phase != SyncPhase.idle) {
      _hasStarted = true;
    } else if (_hasStarted &&
        widget.phase == SyncPhase.idle &&
        oldWidget.phase != SyncPhase.idle) {
      // 若异常中断导致 phase 从运行中强行跌回 idle，UI 需要退回
      _hasStarted = false;
    }

    // Detect phase transition from pulling to merging for the typing effect
    if (oldWidget.phase == SyncPhase.pulling &&
        widget.phase == SyncPhase.merging) {
      _startTypingEffect();
    }
  }

  Future<void> _startTypingEffect() async {
    setState(() {
      _isTyping = true;
      _typedText = '';
    });

    const suffix = '拉取完成';
    for (int i = 0; i < suffix.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _typedText = suffix.substring(0, i + 1);
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      _isTyping = false;
    });
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = Theme.of(context).extension<SkinExtension>()!;

    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          UiSizes.spaceS,
          UiSizes.spaceXL,
          UiSizes.spaceS,
          UiSizes.spaceS,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(UiSizes.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: AnimatedCrossFade(
          firstChild: _buildPromptContent(skin),
          secondChild: _buildProgressContent(skin),
          crossFadeState: _hasStarted
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.center,
          layoutBuilder: (topChild, topKey, bottomChild, bottomKey) {
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  key: bottomKey,
                  top: 0,
                  left: 0,
                  right: 0,
                  child: bottomChild,
                ),
                Positioned(key: topKey, child: topChild),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPromptContent(SkinExtension skin) {
    return SizedBox(
      height: 140,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '曲库内暂无歌曲数据\n是否同步？',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF555555),
              height: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: UiSizes.spaceXL),
          Row(
            children: [
              Expanded(
                child: ConfirmButton(
                  text: '确认',
                  height: 48,
                  fontSize: 16,
                  onPressed: () {
                    setState(() {
                      _hasStarted = true;
                    });
                    widget.onConfirm();
                  },
                ),
              ),
              const SizedBox(width: UiSizes.spaceS),
              Expanded(
                child: ConfirmButton(
                  text: '取消',
                  height: 48,
                  fontSize: 16,
                  onPressed: () async {
                    setState(() => _isVisible = false);
                    await Future.delayed(const Duration(milliseconds: 150));
                    widget.onCancel();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressContent(SkinExtension skin) {
    final String dots = '.' * _dotCount;

    String leftText = '';
    String rightText = '';
    double progressValue = 0.0;

    if (widget.phase == SyncPhase.pulling) {
      leftText = '正在拉取歌曲数据...';
      progressValue = 0.0;
    } else if (widget.phase == SyncPhase.merging) {
      if (_isTyping) {
        leftText = '正在拉取歌曲数据...$_typedText';
        progressValue = 0.0;
      } else {
        leftText = '合并中...';
        rightText = '歌曲数: ${widget.current}/${widget.total}';
        progressValue = widget.total > 0 ? widget.current / widget.total : 0.0;
      }
    } else if (widget.phase == SyncPhase.idle) {
      if (_hasStarted) {
        leftText = '准备中...';
      }
    }

    return SizedBox(
      height: 140,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              '正在同步中$dots',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF555555),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leftText,
                style: const TextStyle(fontSize: 14, color: Color(0xFF777777)),
              ),
              Text(
                rightText,
                style: const TextStyle(fontSize: 14, color: Color(0xFF777777)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _isTyping || widget.phase == SyncPhase.pulling
                  ? 0.0
                  : progressValue,
              minHeight: 6,
              backgroundColor: skin.light.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(skin.medium),
            ),
          ),
        ],
      ),
    );
  }
}
