import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../kernel/state/toast_provider.dart';
import 'toast_card.dart';

// ============================================================
// ==================== Toast 覆盖层 ==========================
// ============================================================

class ToastOverlay extends StatefulWidget {
  final Widget child;

  const ToastOverlay({super.key, required this.child});

  @override
  State<ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<ToastOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        const Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: _ToastStackManager(key: ValueKey('ToastStackManager')),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ==================== Toast 堆栈管理器 ======================
// ============================================================

class _ToastStackManager extends StatefulWidget {
  const _ToastStackManager({super.key});

  @override
  State<_ToastStackManager> createState() => _ToastStackManagerState();
}

class _ToastStackManagerState extends State<_ToastStackManager>
    with TickerProviderStateMixin {
  final List<ToastEntry> _entries = [];

  static const double _bottomPaddingRatio = 0.05;
  static const double _slotHeight = 42.0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ToastProvider>();
    provider.addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    if (mounted) {
      context.read<ToastProvider>().removeListener(_onProviderUpdate);
    }
    for (var entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _onProviderUpdate() {
    if (!mounted) return;
    final provider = context.read<ToastProvider>();
    final currentToasts = provider.toasts;

    if (currentToasts.isNotEmpty) {
      final latest = currentToasts.last;
      if (!_entries.any((e) => e.item.id == latest.id)) {
        _handleNewToast(latest);
      }
    }
  }

  // -------------------- 新 Toast 处理 ---------------------

  void _handleNewToast(ToastItem item) {
    late ToastEntry newEntry;

    newEntry = ToastEntry(
      item: item,
      vsync: this,
      onDismissComplete: (id) {
        if (!mounted) return;
        setState(() {
          _entries.removeWhere((e) => e.item.id == id);
        });
        context.read<ToastProvider>().remove(id);
      },
      onSqueezeTrigger: () {
        if (!mounted) return;
        _triggerGlobalSqueeze(newEntry);
      },
      onAutoDismissStart: (entry) {
        if (!mounted) return;
        _triggerCascadeDismiss(entry);
      },
    );

    newEntry.logicSlot = 1;

    setState(() {
      _entries.add(newEntry);
    });

    newEntry.startEntry();
  }

  // -------------------- 挤压逻辑 (槽位转移) ---------------------

  void _triggerGlobalSqueeze(ToastEntry triggerEntry) {
    final triggerIndex = _entries.indexOf(triggerEntry);
    if (triggerIndex == -1) return;

    // 只挤压比触发者更早添加的 Toast
    for (int i = 0; i < triggerIndex; i++) {
      final target = _entries[i];
      if (target.isExiting) continue;

      if (target.targetSlot == 1) {
        target.moveToSlot(2);
      } else if (target.targetSlot == 2) {
        target.startExit();
      }
    }
  }

  // -------------------- 级联销毁 (自动超时) ---------------------

  void _triggerCascadeDismiss(ToastEntry exitingEntry) {
    if (exitingEntry.logicSlot == 2) {
      final slot1Entry = _entries.firstWhereOrNull(
        (e) => e.logicSlot == 1 && !e.isExiting,
      );
      if (slot1Entry != null) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && slot1Entry.isAlive && !slot1Entry.isExiting) {
            slot1Entry.moveToSlot(2);
          }
        });
      }
    }
  }

  // -------------------- 渲染逻辑 ---------------------

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).size.height * _bottomPaddingRatio;

    return Stack(
      children: [
        for (var entry in _entries)
          AnimatedBuilder(
            animation: Listenable.merge([
              entry.entryController,
              entry.positionController,
              entry.exitController,
            ]),
            builder: (context, child) {
              double opacity = 1.0;
              double offsetY = 0;

              const double slot1Y = _slotHeight;
              const double slot2Y = 0.0;
              const double slot3Y = -150.0;

              if (entry.isExiting) {
                final currentY = lerpDouble(
                  slot2Y,
                  slot1Y,
                  entry.positionCurve.value,
                )!;
                offsetY = lerpDouble(currentY, slot3Y, entry.exitCurve.value)!;

                if (entry.exitController.value > 0.8) {
                  opacity = 1.0 - ((entry.exitController.value - 0.8) * 5);
                }
              } else if (entry.entryController.isAnimating &&
                  entry.targetSlot == 1) {
                offsetY = lerpDouble(-50.0, slot1Y, entry.entryCurve.value)!;
              } else {
                offsetY = lerpDouble(
                  slot2Y,
                  slot1Y,
                  entry.positionCurve.value,
                )!;
              }

              return Positioned(
                bottom: bottomPadding + offsetY,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: GameToastCard(
                      message: entry.item.message,
                      type: entry.item.type,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

// ============================================================
// ===================== Toast 条目 ===========================
// ============================================================

class ToastEntry {
  final ToastItem item;
  final TickerProvider vsync;
  final Function(String) onDismissComplete;
  final VoidCallback onSqueezeTrigger;
  final Function(ToastEntry) onAutoDismissStart;

  int logicSlot = 1;
  int targetSlot = 1;

  bool isExiting = false;
  bool isAlive = true;

  Timer? _autoDismissTimer;

  late final AnimationController entryController;
  late final Animation<double> entryCurve;

  late final AnimationController positionController;
  late final Animation<double> positionCurve;

  late final AnimationController exitController;
  late final Animation<double> exitCurve;

  ToastEntry({
    required this.item,
    required this.vsync,
    required this.onDismissComplete,
    required this.onSqueezeTrigger,
    required this.onAutoDismissStart,
  }) {
    entryController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 380),
    );
    entryCurve = CurvedAnimation(
      parent: entryController,
      curve: Curves.easeOutBack,
    );

    bool squeezeFired = false;
    entryController.addListener(() {
      if (!squeezeFired && entryController.value >= 0.5) {
        squeezeFired = true;
        onSqueezeTrigger();
      }
    });

    positionController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 240),
      value: 1.0,
    );
    positionCurve = CurvedAnimation(
      parent: positionController,
      curve: Curves.easeInOut,
    );

    exitController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 240),
    );
    exitCurve = CurvedAnimation(parent: exitController, curve: Curves.easeIn);
    exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        isAlive = false;
        onDismissComplete(item.id);
      }
    });

    _startTimer();
  }

  void _startTimer() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 4), () {
      if (isAlive && !isExiting) {
        startExit();
        onAutoDismissStart(this);
      }
    });
  }

  void cancelAutoDismiss() {
    _autoDismissTimer?.cancel();
  }

  void startEntry() {
    entryController.forward();
  }

  void moveToSlot(int slot) {
    targetSlot = slot;

    if (entryController.isAnimating) {
      entryController.animateTo(1.0, duration: const Duration(milliseconds: 1));
    }

    if (slot == 2) {
      positionController.animateTo(0.0).then((_) => logicSlot = 2);
    } else if (slot == 1) {
      positionController.animateTo(1.0).then((_) => logicSlot = 1);
    }
  }

  void startExit() {
    if (isExiting) return;
    isExiting = true;
    logicSlot = 3;
    exitController.forward();
  }

  void dispose() {
    _autoDismissTimer?.cancel();
    entryController.dispose();
    positionController.dispose();
    exitController.dispose();
  }
}

// ============================================================
// ======================= 工具扩展 ===========================
// ============================================================

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
