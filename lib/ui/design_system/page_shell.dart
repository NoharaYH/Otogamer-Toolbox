import 'dart:ui';
import 'package:flutter/material.dart';
import 'visual_skins/skin_extension.dart';

/// 页面外壳
/// 提供：背景 + 白色毛玻璃底板 + 内容区域
///
/// 使用场景：主页（需要统一背景和毛玻璃效果的页面）
/// 不使用场景：设置页、WebView 页（这些页面有自己的布局）
class PageShell extends StatelessWidget {
  final Widget child;
  final bool showGlassCard;

  const PageShell({super.key, required this.child, this.showGlassCard = true});

  @override
  Widget build(BuildContext context) {
    // 获取当前皮肤
    final skin = Theme.of(context).extension<SkinExtension>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. 背景层（从皮肤系统取）
          if (skin != null)
            Positioned.fill(child: skin.buildBackground(context)),

          // 2. 毛玻璃底板（可选）
          if (showGlassCard)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.05,
              left: MediaQuery.of(context).size.width * 0.05,
              right: MediaQuery.of(context).size.width * 0.05,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(color: Colors.white.withOpacity(0.8)),
                ),
              ),
            ),

          // 3. 内容区
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
