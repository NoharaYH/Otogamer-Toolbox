import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_assets.dart';
import '../config/game_config.dart';
import '../providers/game_provider.dart';

// Components
import '../widgets/transfer_mode_card.dart';
import '../widgets/background/maimai_background.dart';
import '../widgets/background/chunithm_background.dart';
import '../widgets/home/sticky_dot_indicator.dart';

// Pages
import 'settings_page.dart';

// Services
import '../services/storage_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // We keep some ephemeral state here (Login/Sync) until we have a proper UserProvider
  bool isMaimaiLoggedIn = false;
  bool isChunithmLoggedIn = false;
  bool isSyncing = false;

  // New Transfer Mode State (0: DF, 1: Both, 2: LXNS)
  // These are kept local to page for now as they are per-session UI choice
  int _maimaiTransferMode = 0;
  int _chunithmTransferMode = 0;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
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

  @override
  Widget build(BuildContext context) {
    // Access providers
    final gameProvider = Provider.of<GameProvider>(context);
    final pageController = gameProvider.pageController;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Dynamic Background Layer (Cross-fading)
          _buildBackgroundStack(pageController),

          // 2. Glassmorphism Card (Static container)
          _buildGlassCard(),

          // 3. Page Indicator (Sticky dots)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05 + 100,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: pageController,
                builder: (context, _) {
                  // Dynamic Color interpolation
                  double page = 0;
                  try {
                    page = pageController.page ?? 0;
                  } catch (_) {}
                  final Color activeColor = Color.lerp(
                    GameThemeConfig.maimai.primaryColor,
                    GameThemeConfig.chunithm.primaryColor,
                    page.clamp(0.0, 1.0),
                  )!;

                  return StickyDotIndicator(
                    controller: pageController,
                    count: 2,
                    activeColor: activeColor,
                  );
                },
              ),
            ),
          ),

          // 4. Content Layer (Swipeable PageView)
          Positioned.fill(
            child: PageView(
              controller: pageController,
              onPageChanged: gameProvider.onPageChanged,
              children: [
                _buildFadePage(
                  index: 0,
                  pageController: pageController,
                  child: _buildMaimaiContent(),
                ),
                _buildFadePage(
                  index: 1,
                  pageController: pageController,
                  child: _buildChunithmContent(),
                ),
              ],
            ),
          ),

          // 5. Header (Settings Button)
          _buildHeader(),
        ],
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildBackgroundStack(PageController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double page = 0;
        try {
          page = controller.page ?? 0;
        } catch (_) {}

        return Stack(
          fit: StackFit.expand,
          children: [
            // Maimai is base
            const MaimaiBackground(),
            // Chunithm fades in on top
            IgnorePointer(
              child: Opacity(
                opacity: page.clamp(0.0, 1.0),
                child: const ChunithmBackground(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlassCard() {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.only(
        top: size.height * 0.05,
        left: size.width * 0.05,
        right: size.width * 0.05,
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
            child: Container(color: Colors.white.withOpacity(0.8)),
          ),
        ),
      ),
    );
  }

  Widget _buildMaimaiContent() {
    return _buildLogoContent(
      logoPath: AppAssets.logoMaimai,
      subtitle: 'MaiMai DX Prober',
      themeColor: GameThemeConfig.maimai.primaryColor,
      child: _buildMaimaiTransferCard(),
    );
  }

  Widget _buildChunithmContent() {
    return _buildLogoContent(
      logoPath: AppAssets.logoChunithm,
      subtitle: 'CHUNITHM Prober',
      themeColor: GameThemeConfig.chunithm.primaryColor,
      child: _buildChunithmTransferCard(),
    );
  }

  Widget _buildMaimaiTransferCard() {
    return TransferModeCard(
      baseColor: Colors.white.withOpacity(0.95),
      borderColor: Colors.white.withOpacity(0.6),
      shadowColor: GameThemeConfig.maimai.shadowColor.withOpacity(0.1),
      containerColor: GameThemeConfig.maimai.containerColor,
      activeColor: GameThemeConfig.maimai.primaryColor,
      gradientColor: GameThemeConfig.maimai.gradientStart,
      mode: _maimaiTransferMode,
      onModeChanged: (val) => setState(() => _maimaiTransferMode = val),
      gameType: 0,
    );
  }

  Widget _buildChunithmTransferCard() {
    return TransferModeCard(
      baseColor: Colors.white.withOpacity(0.95),
      borderColor: Colors.white.withOpacity(0.6),
      shadowColor: GameThemeConfig.chunithm.shadowColor.withOpacity(0.1),
      containerColor: GameThemeConfig.chunithm.containerColor,
      activeColor: GameThemeConfig.chunithm.primaryColor,
      gradientColor: GameThemeConfig.chunithm.gradientStart,
      mode: _chunithmTransferMode,
      onModeChanged: (val) => setState(() => _chunithmTransferMode = val),
      gameType: 1,
    );
  }

  Widget _buildLogoContent({
    required String logoPath,
    required String subtitle,
    required Color themeColor,
    Widget? child,
  }) {
    final size = MediaQuery.of(context).size;

    // The Glass Card starts at 5% height.
    // We want the content to start inside the card with some padding.
    final double cardTopStart = size.height * 0.05;
    const double internalPadding = 7.0;

    // Config: Position logic
    // The Indicator is fixed at [CardTop + 100] and has height 20.
    // So Indicator Bottom is at [CardTop + 120].
    // We want the Card to start closer now.
    // Original base was 44.0, reducing by ~1/3 -> 30.0

    double gapHeight = 30.0 - internalPadding;
    if (gapHeight < 0) gapHeight = 0;

    return Padding(
      padding: EdgeInsets.only(
        top:
            cardTopStart +
            internalPadding, // Align with card + internal spacing
        left: size.width * 0.05,
        right: size.width * 0.05,
        bottom: 0,
      ),
      child: Column(
        children: [
          // Logo Area with Watermark
          SizedBox(
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Watermark Text (Behind)
                Positioned(
                  top: 32,
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'GameFont',
                      fontSize: 34,
                      fontWeight: FontWeight.normal,
                      color: themeColor.withOpacity(0.2),
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
                // Logo Image (In Front)
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(logoPath, height: 80, fit: BoxFit.contain),
                ),
              ],
            ),
          ),

          if (child != null) ...[
            // Dynamic spacer to keep Card fixed relative to Indicator
            SizedBox(height: gapHeight),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildFadePage({
    required int index,
    required PageController pageController,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double page = 0;
        try {
          page = pageController.page ?? 0;
        } catch (_) {}
        final double width = MediaQuery.of(context).size.width;
        final double diff = (page - index);
        final double absDiff = diff.abs();
        final double opacity = (1 - absDiff).clamp(0.0, 1.0);

        // Parallax & Scale Effect
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
}
