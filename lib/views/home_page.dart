import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'settings_page.dart';
import 'login_web_page.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../widgets/transfer_mode_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();

  // 登录状态
  bool isMaimaiLoggedIn = false;
  bool isChunithmLoggedIn = false;
  bool isSyncing = false;
  // 0: Diving Fish (水鱼), 1: Both (双平台), 2: LXNS (落雪)
  int _maimaiTransferMode = 0;
  int _chunithmTransferMode = 0;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final maiCookie = await StorageService.read(StorageService.kMaimaiCookie);
    final chuniCookie = await StorageService.read(
      StorageService.kChunithmCookie,
    );
    if (mounted) {
      setState(() {
        isMaimaiLoggedIn = maiCookie != null;
        isChunithmLoggedIn = chuniCookie != null;
      });
    }
  }

  Future<void> _handleLogin(int gameType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginWebPage(gameType: gameType)),
    );
    if (result != null && result is String) {
      if (gameType == 0) {
        await StorageService.save(StorageService.kMaimaiCookie, result);
      } else {
        await StorageService.save(StorageService.kChunithmCookie, result);
      }
      _checkLoginStatus();
    }
  }

  Future<void> _handleSync(int gameType) async {
    setState(() => isSyncing = true);
    String result = gameType == 0
        ? await ApiService.syncMaimai()
        : await ApiService.syncChunithm();
    if (mounted) {
      setState(() => isSyncing = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('同步结果'),
          content: Text(result),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('好的'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. 背景层
          _buildBackgroundStack(),

          // 2. Glass Card Background (Static, does not fade)
          _buildGlassCard(),

          // 3. Page Indicator (Sticky dots below logo)
          _buildPageIndicator(),

          // 4. Gesture/Swipe Layer (PageView driving animation + Logo Content)
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              children: [
                _buildFadePage(index: 0, child: _buildMaimaiContent()),
                _buildFadePage(index: 1, child: _buildChunithmContent()),
              ],
            ),
          ),

          // 5. 顶部 Header (Logo + Settings)
          _buildHeader(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      top:
          MediaQuery.of(context).size.height * 0.05 +
          100, // Below logo (~24+60+16 padding)
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            final double page = _safePage;
            // 0.0 = Maimai, 1.0 = Chunithm

            // Effect parameters
            const double dotSize = 8.0;
            const double spacing = 16.0;
            const int count = 2;
            final double totalWidth =
                (count * dotSize) + ((count - 1) * spacing);

            // Colors
            // Interpolate between Pink (Maimai) and Blue (Chunithm)
            final Color activeColor = Color.lerp(
              Colors.pinkAccent,
              Colors.blueAccent,
              page.clamp(0.0, 1.0),
            )!;

            return SizedBox(
              width: totalWidth + 20, // ample space
              height: 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Fixed Background Dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(count, (index) {
                      return Container(
                        width: dotSize,
                        height: dotSize,
                        margin: EdgeInsets.only(left: index == 0 ? 0 : spacing),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),

                  // Custom Drawn Worm
                  CustomPaint(
                    size: Size(totalWidth, dotSize),
                    painter: _StickyDotPainter(
                      page: page,
                      color: activeColor,
                      dotSize: dotSize,
                      spacing: spacing,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double get _safePage {
    if (!_pageController.hasClients) return 0.0;
    try {
      return _pageController.page ?? 0.0;
    } catch (_) {
      for (final position in _pageController.positions) {
        if (position.haveDimensions && position.viewportDimension > 0) {
          return position.pixels / position.viewportDimension;
        }
      }
      return 0.0;
    }
  }

  Widget _buildBackgroundStack() {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        final double page = _safePage;
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildMaimaiBackground(),
            IgnorePointer(
              child: Opacity(
                opacity: page.clamp(0.0, 1.0),
                child: _buildChunithmBackground(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMaimaiBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [Color(0xFFFFB7CD), Color(0xFFFF59A1)],
            ),
          ),
        ),
        _RotatingImage(
          assetPath: 'assets/background/maimaidx/bg_pattern.png',
          duration: const Duration(seconds: 240),
          scale: 3.5,
        ),
        _RotatingImage(
          assetPath: 'assets/background/maimaidx/circle_white.png',
          duration: const Duration(seconds: 180),
          scale: 1.4,
          reverse: true,
        ),
        _RotatingImage(
          assetPath: 'assets/background/maimaidx/circle_yellow.png',
          duration: const Duration(seconds: 280),
          scale: 1.7,
        ),
        _RotatingImage(
          assetPath: 'assets/background/maimaidx/circle_colorful.png',
          duration: const Duration(seconds: 310),
          scale: 1.7,
          reverse: true,
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Image.asset(
            'assets/background/maimaidx/top_left.png',
            width: 200,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Image.asset(
            'assets/background/maimaidx/top_right.png',
            width: MediaQuery.of(context).size.width * 0.4,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Image.asset(
            'assets/background/maimaidx/bottom_left.png',
            width: MediaQuery.of(context).size.width * 0.4,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Image.asset(
            'assets/background/maimaidx/bottom_right.png',
            width: 200,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildChunithmBackground() {
    const double designWidth = 393.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = constraints.maxWidth / designWidth;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/background/chunithm/bg.jpg.webp',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: -515 * scale,
              bottom: 0,
              width: 1500 * scale,
              height: 733 * scale,
              child: Image.asset(
                'assets/background/chunithm/verse-town.png.webp',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                'assets/background/chunithm/top_right.png.webp',
                width: constraints.maxWidth * 1.7,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Image.asset(
                'assets/background/chunithm/bottom_left.png.webp',
                width: constraints.maxWidth * 1.7,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 16,
      child: IconButton(
        icon: const Icon(Icons.settings, color: Colors.black87),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        ),
      ),
    );
  }

  Widget _buildFadePage({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        final double page = _safePage;
        final double width = MediaQuery.of(context).size.width;
        final double diff = (page - index);
        final double absDiff = diff.abs();
        final double opacity = (1 - absDiff).clamp(0.0, 1.0);
        final double centerOffset = diff * width;
        final double slideEffect = -diff * 100.0;
        final double scaleX = (1 - (absDiff * 0.2)).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(centerOffset + slideEffect, 0),
          child: Transform(
            transform: Matrix4.diagonal3Values(scaleX, 1.0, 1.0),
            alignment: Alignment.center,
            child: Opacity(
              opacity: opacity,
              child: IgnorePointer(ignoring: absDiff > 0.5, child: child),
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildChunithmContent() {
    return _buildLogoContent(
      logoPath: 'assets/logo/top_main_logo.webp',
      child: _buildChunithmTransferCard(),
    );
  }

  Widget _buildGlassCard() {
    final size = MediaQuery.of(context).size;
    final topMargin = size.height * 0.05; // 5%
    final horizontalMargin = size.width * 0.05;

    return Padding(
      padding: EdgeInsets.only(
        top: topMargin,
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: 0,
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              color: Colors.white.withOpacity(0.8), // 80% Opacity
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoContent({required String logoPath, Widget? child}) {
    final size = MediaQuery.of(context).size;
    final topMargin = size.height * 0.05;
    final horizontalMargin = size.width * 0.05;

    return Padding(
      padding: EdgeInsets.only(
        top: topMargin,
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: 0,
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Image.asset(logoPath, height: 60, fit: BoxFit.contain),
          if (child != null) ...[
            const SizedBox(
              height: 50,
            ), // Space for indicator (approx 20 + padding)
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildMaimaiContent() {
    return _buildLogoContent(
      logoPath: 'assets/logo/UI_CMN_TabTitle_MaimaiTitle_Ver260.png',
      child: _buildMaimaiTransferCard(),
    );
  }

  Widget _buildMaimaiTransferCard() {
    return TransferModeCard(
      baseColor: Colors.white.withOpacity(0.95),
      borderColor: Colors.white.withOpacity(0.6),
      shadowColor: const Color(0xFFFF59A1).withOpacity(0.1),
      containerColor: const Color(0xFFFF9EBF),
      activeColor: const Color(0xFFFF59A1),
      gradientColor: const Color(0xFFFFF0F5),
      mode: _maimaiTransferMode,
      onModeChanged: (val) => setState(() => _maimaiTransferMode = val),
      gameType: 0, // Maimai
    );
  }

  Widget _buildChunithmTransferCard() {
    return TransferModeCard(
      baseColor: Colors.white.withOpacity(0.95),
      borderColor: Colors.white.withOpacity(0.6),
      shadowColor: Colors.blueAccent.withOpacity(0.1),
      containerColor: const Color(0xFF90CAF9),
      activeColor: Colors.blueAccent,
      gradientColor: const Color(0xFFF0F8FF),
      mode: _chunithmTransferMode,
      onModeChanged: (val) => setState(() => _chunithmTransferMode = val),
      gameType: 1, // Chunithm
    );
  }
}

class _StickyDotPainter extends CustomPainter {
  final double page;
  final Color color;
  final double dotSize;
  final double spacing;

  _StickyDotPainter({
    required this.page,
    required this.color,
    required this.dotSize,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Calculate worm bounds
    // We have 2 dots at index 0 and 1.
    // Distance between centers:
    final double distance = dotSize + spacing;

    // safePage can be < 0 or > 1 during overscroll, clamp it for drawing
    final double p = page.clamp(0.0, 1.0);

    // Worm effect:
    // At 0.0: pos = 0, width = dotSize
    // At 0.5: pos = 0, width = dotSize + distance/2 ?? No, usually centered.
    // "Sticky" usually means:
    // Front edge moves fast from 0.0 to 0.5, then slow/normal.
    // Back edge moves slow/stays from 0.0 to 0.5, then fast.

    // Let's model current index `current` and next `next`.
    // Here only 0 and 1.

    double left = 0.0;
    double right = dotSize;

    if (p < 0.5) {
      // Growing phase (moving to right)
      // Left stays roughly at 0 (or moves slightly), Right moves fast to cover gap
      // Local progress 0 -> 1 for range 0 -> 0.5 => p * 2
      double localP = p * 2;
      left = 0.0 + (localP * (distance * 0.1)); // faint movement
      right = dotSize + (localP * distance);
    } else {
      // Shrinking phase (arriving at 1)
      // Left moves fast to catch up. Right settles.
      // Local progress 0 -> 1 for range 0.5 -> 1.0 => (p - 0.5) * 2
      double localP = (p - 0.5) * 2;
      left = (distance * 0.1) + (localP * (distance * 0.9));
      right = dotSize + distance; // Full span reached roughly
    }

    // Add simple smoothening or exact worm:
    // Center point logic is easier?
    // Let's use Rect.ltrb

    // Better simple sticky math:
    // Left anchor: moves strictly when p > 0.5 (accelerates)
    // Right anchor: moves strictly when p < 0.5 (decelerates?)
    // Actually:
    // Left x = startX + distance * interval(p, 0.5, 1.0)
    // Right x = startX + dotSize + distance * interval(p, 0.0, 0.5)
    // where interval(val, start, end) maps val to 0..1

    double interval(double val, double start, double end) {
      return ((val - start) / (end - start)).clamp(0.0, 1.0);
    }

    // We adjust drawing coordinate to center of the widget
    // Widget width = totalWidth.
    // Dot 0 is at 0.

    double startX = 0; // Relative to canvas

    // Animate
    // Forward (0->1)
    double l =
        startX +
        distance *
            CurveTween(
              curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
            ).transform(p);
    double r =
        startX +
        dotSize +
        distance *
            CurveTween(
              curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
            ).transform(p);

    // Draw Rrect
    final RRect rect = RRect.fromLTRBR(
      l,
      0,
      r,
      dotSize,
      Radius.circular(dotSize / 2),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_StickyDotPainter oldDelegate) {
    return oldDelegate.page != page || oldDelegate.color != color;
  }
}

class _RotatingImage extends StatefulWidget {
  final String assetPath;
  final Duration duration;
  final double scale;
  final bool reverse;

  const _RotatingImage({
    required this.assetPath,
    required this.duration,
    this.scale = 1.0,
    this.reverse = false,
  });

  @override
  State<_RotatingImage> createState() => _RotatingImageState();
}

class _RotatingImageState extends State<_RotatingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(_RotatingImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double angle = _controller.value * 2 * 3.14159;
            return Transform.rotate(
              angle: widget.reverse ? -angle : angle,
              child: Transform.scale(scale: widget.scale, child: child!),
            );
          },
          child: Image.asset(widget.assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
