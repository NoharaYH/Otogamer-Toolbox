import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../kit_shared/kit_bounce_scaler.dart';

/// 设置页下拉选择触发行 + 弹出菜单 (kit_setting 原子组件)
///
/// 外观：灰色低对比度圆角背景行，左侧小图标，中部当前选项文字，右侧展开箭头。
/// 弹出：圆角白色浮层，逐项渲染单选指示图标，选中态使用注入的 accentColor 高亮。
///
/// 泛型 T 为选项值类型。accentColor 由业务页从 ThemeExtension 取出后传入。
class SettingMenu<T> extends StatelessWidget {
  final List<T> options;
  final List<String> labels;
  final T current;
  final ValueChanged<T> onSelect;
  final Color accentColor;
  final IconData leadingIcon;

  const SettingMenu({
    super.key,
    required this.options,
    required this.labels,
    required this.current,
    required this.onSelect,
    required this.accentColor,
    this.leadingIcon = Icons.palette_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final currentLabel = labels[options.indexOf(current)];

    return Builder(
      builder: (btnCtx) {
        return KitBounceScaler(
          onTap: () async {
            final result = await showMenu<T>(
              context: context,
              position: _menuPosition(btnCtx),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white.withValues(alpha: 0.98),
              items: List.generate(options.length, (i) {
                final isSelected = current == options[i];
                return PopupMenuItem<T>(
                  value: options[i],
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: isSelected ? accentColor : UiColors.grey400,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? accentColor : UiColors.grey700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
            if (result != null) onSelect(result);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: UiColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  leadingIcon,
                  size: 18,
                  color: accentColor.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: UiColors.grey700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.unfold_more,
                  size: 18,
                  color: UiColors.grey400,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  RelativeRect _menuPosition(BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    return RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + box.size.height,
      offset.dx + box.size.width,
      offset.dy + box.size.height + 200,
    );
  }
}

/// 设置页分段选择开关（Tab 型切换器）(kit_setting 原子组件)
///
/// 浅灰色圆角背景包裹，选中项填充 accentColor 纯色背景+白色文字，
/// 未选中项灰色文字无背景，外形为紧凑内嵌式 Tab 切换器。
class SettingSegmentedSwitch extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color accentColor;

  const SettingSegmentedSwitch({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UiColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isSelected = selectedIndex == i;
          return KitBounceScaler(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : UiColors.grey500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
