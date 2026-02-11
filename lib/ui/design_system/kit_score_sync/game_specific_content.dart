import 'package:flutter/material.dart';
import '../constants/assets.dart';
import '../kit_shared/confirm_button.dart';

// ============================================================
// ============== 舞萌专属：难度选择器 =========================
// ============================================================

class MaimaiDifficultySelector extends StatefulWidget {
  final Color activeColor;
  final VoidCallback onImport;

  const MaimaiDifficultySelector({
    super.key,
    required this.activeColor,
    required this.onImport,
  });

  @override
  State<MaimaiDifficultySelector> createState() =>
      _MaimaiDifficultySelectorState();
}

class _MaimaiDifficultySelectorState extends State<MaimaiDifficultySelector> {
  // 0: Basic, 1: Advanced, 2: Expert, 3: Master, 4: Re:Master, 5: Utage
  final Set<int> _selectedDifficulties = {0, 1, 2, 3, 4, 5};

  final List<Map<String, dynamic>> _difficulties = [
    {
      'name': 'Basic',
      'asset': AppAssets.difficultyBasic,
      'color': const Color(0xFF45C124),
    },
    {
      'name': 'Advanced',
      'asset': AppAssets.difficultyAdvanced,
      'color': const Color(0xFFFFBA01),
    },
    {
      'name': 'Expert',
      'asset': AppAssets.difficultyExpert,
      'color': const Color(0xFFFF5A66),
    },
    {
      'name': 'Master',
      'asset': AppAssets.difficultyMaster,
      'color': const Color(0xFF9F51DC),
    },
    {
      'name': 'Re:Master',
      'asset': AppAssets.difficultyRemaster,
      'color': const Color(0xFFE6E6E6),
    },
    {
      'name': 'Utage',
      'asset': AppAssets.difficultyUtage,
      'color': const Color(0xFFFF6FFD),
    },
  ];

  void _toggleDifficulty(int index) {
    setState(() {
      if (_selectedDifficulties.contains(index)) {
        _selectedDifficulties.remove(index);
      } else {
        _selectedDifficulties.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: _difficulties.length,
          itemBuilder: (context, index) {
            final difficulty = _difficulties[index];
            final isSelected = _selectedDifficulties.contains(index);

            return _DifficultyButton(
              difficulty: difficulty,
              isSelected: isSelected,
              onTap: () => _toggleDifficulty(index),
            );
          },
        ),
        const SizedBox(height: 10),
        ConfirmButton(
          text: '开始导入',
          state: ConfirmButtonState.ready, // 默认就是 ready，禁用由 onPressedNull 控制
          onPressed: _selectedDifficulties.isEmpty ? null : widget.onImport,
        ),
      ],
    );
  }
}

class _DifficultyButton extends StatefulWidget {
  final Map<String, dynamic> difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DifficultyButton> createState() => _DifficultyButtonState();
}

class _DifficultyButtonState extends State<_DifficultyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // 原始矩阵 (Identity)
  static const List<double> _identityMatrix = [
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  // 变暗矩阵 (Saturation 50% + Brightness 50%)
  static const List<double> _dimmedMatrix = [
    0.303,
    0.179,
    0.018,
    0,
    0,
    0.053,
    0.429,
    0.018,
    0,
    0,
    0.053,
    0.179,
    0.268,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // 按下动画时长
    );
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _scaleController.forward();
  }

  void _onPointerUp(PointerEvent event) {
    _scaleController.reverse();
  }

  List<double> _lerpMatrix(double t) {
    // 线性插值计算当前矩阵
    return List.generate(20, (index) {
      return _identityMatrix[index] +
          (_dimmedMatrix[index] - _identityMatrix[index]) * t;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.difficulty['color'] as Color;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnimation.value, child: child),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: widget.isSelected ? 0.0 : 1.0,
              end: widget.isSelected ? 0.0 : 1.0,
            ),
            duration: const Duration(milliseconds: 200), // 颜色淡入淡出时长
            builder: (context, value, child) {
              return ColorFiltered(
                colorFilter: ColorFilter.matrix(_lerpMatrix(value)),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(6),
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 34,
                    child: Image.asset(
                      widget.difficulty['asset'],
                      height: 34,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ============== 中二专属：难度选择器（待开发）================
// ============================================================

class ChunithmDifficultySelector extends StatefulWidget {
  final Color activeColor;
  final VoidCallback onImport;

  const ChunithmDifficultySelector({
    super.key,
    required this.activeColor,
    required this.onImport,
  });

  @override
  State<ChunithmDifficultySelector> createState() =>
      _ChunithmDifficultySelectorState();
}

class _ChunithmDifficultySelectorState
    extends State<ChunithmDifficultySelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              '中二难度选择器（待开发）',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
        ConfirmButton(text: '开始导入', onPressed: widget.onImport),
      ],
    );
  }
}
