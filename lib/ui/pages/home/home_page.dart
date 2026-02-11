import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system/constants/assets.dart';

import '../../../kernel/state/game_provider.dart';
import '../../../kernel/di/injection.dart';

// Components
import '../transfer/widgets/transfer_mode_card.dart';

import '../../design_system/visual_skins/implementations/maimai_dx/circle_background.dart';
import '../../design_system/visual_skins/implementations/chunithm/verse_background.dart';
import '../../design_system/kit_shared/sticky_dot_indicator.dart';

// Pages
import '../settings/settings_page.dart';

// Services
import '../../../kernel/services/storage_service.dart';

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
    final maiCookie = await getIt<StorageService>().read(
      StorageService.kMaimaiCookie,
    );
    final chuniCookie = await getIt<StorageService>().read(
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
    final gameProvider = context.watch<GameProvider>();
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
                  final double page = pageController.hasClients
                      ? (pageController.page ?? 0)
                      : 0;
                  final Color activeColor = Color.lerp(
                    MaimaiSkin().medium,
                    ChunithmSkin().medium,
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
        final double page = controller.hasClients ? (controller.page ?? 0) : 0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Maimai is base
            MaimaiSkin().buildBackground(context),
            // Chunithm fades in on top
            IgnorePointer(
              child: Opacity(
                opacity: page.clamp(0.0, 1.0),
                child: ChunithmSkin().buildBackground(context),
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
      themeColor: MaimaiSkin().medium,
      child: _buildMaimaiTransferCard(),
    );
  }

  Widget _buildChunithmContent() {
    return _buildLogoContent(
      logoPath: AppAssets.logoChunithm,
      subtitle: 'CHUNITHM Prober',
      themeColor: ChunithmSkin().medium,
      child: _buildChunithmTransferCard(),
    );
  }

  Widget _buildMaimaiTransferCard() {
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [
          MaimaiSkin(), // New system
        ],
      ),
      child: TransferModeCard(
        mode: _maimaiTransferMode,
        onModeChanged: (val) => setState(() => _maimaiTransferMode = val),
        gameType: 0,
      ),
    );
  }

  Widget _buildChunithmTransferCard() {
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [
          ChunithmSkin(), // New system
        ],
      ),
      child: TransferModeCard(
        mode: _chunithmTransferMode,
        onModeChanged: (val) => setState(() => _chunithmTransferMode = val),
        gameType: 1,
      ),
    );
  }

  Widget _buildLogoContent({
    required String logoPath,
    required String subtitle,
    required Color themeColor,
    Widget? child,
  }) {
    final size = MediaQuery.of(context).size;

    final double cardTopStart = size.height * 0.05;
    const double internalPadding = 7.0;

    double gapHeight = 30.0 - internalPadding;
    if (gapHeight < 0) gapHeight = 0;

    return Padding(
      padding: EdgeInsets.only(
        top: cardTopStart + internalPadding,
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

          if (child != null) ...[SizedBox(height: gapHeight), child],
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
        final double page = pageController.hasClients
            ? (pageController.page ?? 0)
            : 0;
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
