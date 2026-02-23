import 'package:flutter/material.dart';

import '../../../../kernel/state/toast_provider.dart';

class GameToastCard extends StatelessWidget {
  final String message;
  final ToastType type;

  const GameToastCard({super.key, required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    // 获取当前皮肤主题色
    // final skin = Theme.of(context).extension<SkinExtension>();

    Color baseColor;
    IconData iconData;

    switch (type) {
      case ToastType.verifying:
        baseColor = const Color(0xFFFFC107); // Yellow
        iconData = Icons.hourglass_top_rounded; // Or generic sync/loading icon
        break;
      case ToastType.confirmed:
        baseColor = const Color(0xFF00C853); // Green
        iconData = Icons.check_circle_outline_rounded;
        break;
      case ToastType.error:
        baseColor = const Color(0xFFFF1744); // Red
        iconData = Icons.error_outline_rounded;
        break;
    }

    final solidBgColor = baseColor.withValues(alpha: 1.0);
    final solidBorderColor = baseColor;
    final textColor = Colors.white;
    final iconColor = Colors.white;

    return Container(
      width: 342,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      decoration: BoxDecoration(
        color: solidBgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: solidBorderColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Icon(iconData, color: iconColor, size: 18),
          const SizedBox(width: 10),
          // Text
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.1,
                decoration: TextDecoration.none,
                fontFamily: 'JiangCheng',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
