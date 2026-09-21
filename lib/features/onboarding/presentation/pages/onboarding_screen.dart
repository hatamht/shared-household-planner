import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/services/onboarding_service.dart';
import '../../../home/presentation/pages/home_screen.dart';

/// Data model for a single onboarding slide.
class OnboardingSlide {
  final IconData icon;
  final Color iconColor;
  final String titleKey;
  final String descKey;
  final String imageAsset;

  const OnboardingSlide({
    required this.icon,
    required this.iconColor,
    required this.titleKey,
    required this.descKey,
    required this.imageAsset,
  });
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  final bool showFallbackIcon;
  const OnboardingScreen({
    super.key,
    this.onFinish,
    this.showFallbackIcon = false,
  });

  static const List<OnboardingSlide> slides = [
    OnboardingSlide(
      icon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF3F51B5),
      titleKey: 'onboarding_slide1_title',
      descKey: 'onboarding_slide1_desc',
      imageAsset: 'assets/images/onboarding/slide1_split_bills.jpg',
    ),
    OnboardingSlide(
      icon: Icons.folder_special_rounded,
      iconColor: Color(0xFF009688),
      titleKey: 'onboarding_slide2_title',
      descKey: 'onboarding_slide2_desc',
      imageAsset: 'assets/images/onboarding/slide2_project_budget.jpg',
    ),
    OnboardingSlide(
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Color(0xFF9C27B0),
      titleKey: 'onboarding_slide3_title',
      descKey: 'onboarding_slide3_desc',
      imageAsset: 'assets/images/onboarding/slide3_smart_debt.jpg',
    ),
    OnboardingSlide(
      icon: Icons.lock_rounded,
      iconColor: Color(0xFF2196F3),
      titleKey: 'onboarding_slide4_title',
      descKey: 'onboarding_slide4_desc',
      imageAsset: 'assets/images/onboarding/slide4_offline_private.jpg',
    ),
  ];

  @override
  State<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == OnboardingScreen.slides.length - 1;

  Future<void> _finishOnboarding() async {
    await OnboardingService.instance.markOnboardingSeen();
    if (!mounted) return;
    if (widget.onFinish != null) {
      widget.onFinish!();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  void _goNext() {
    if (_isLastPage) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleLanguage() {
    final langProvider = context.read<LanguageProvider>();
    final currentCode = langProvider.currentLocale.languageCode;
    langProvider.setLanguage(currentCode == 'en' ? 'vi' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final langCode = context.watch<LanguageProvider>().currentLocale.languageCode;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full-screen PageView with edge-to-edge images ────────────
          Positioned.fill(
            child: PageView.builder(
              key: const Key('onboardingPageView'),
              controller: _pageController,
              itemCount: OnboardingScreen.slides.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return _buildFullScreenSlide(
                  context,
                  OnboardingScreen.slides[index],
                  index,
                  loc,
                );
              },
            ),
          ),

          // ── Top Bar: Skip + Language Switcher with frosted pill style ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip button
                    TextButton(
                      key: const Key('onboardingSkipButton'),
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        backgroundColor: Colors.black.withOpacity(0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                      ),
                      child: Text(
                        loc.translate('onboarding_skip'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),

                    // Quick language toggle
                    OutlinedButton(
                      key: const Key('onboardingLanguageToggle'),
                      onPressed: _toggleLanguage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.black.withOpacity(0.35),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        langCode == 'en' ? 'EN | VI' : 'VI | EN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Controls: Dots Indicator + Action Button ──────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(OnboardingScreen.slides.length, (i) {
                        final isActive = _currentPage == i;
                        return AnimatedContainer(
                          key: Key('onboardingDot_$i'),
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? colorScheme.primary
                                : Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(0.6),
                                      blurRadius: 8,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Next / Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: _isLastPage
                          ? ElevatedButton(
                              key: const Key('onboardingGetStartedButton'),
                              onPressed: _finishOnboarding,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                loc.translate('onboarding_get_started'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              key: const Key('onboardingNextButton'),
                              onPressed: _goNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                loc.translate('onboarding_next'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenSlide(
    BuildContext context,
    OnboardingSlide slide,
    int index,
    AppLocalizations loc,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-screen Graphic Image Asset (with fallback)
        Positioned.fill(
          child: widget.showFallbackIcon
              ? Container(
                  key: Key('onboardingFallbackIcon_$index'),
                  color: slide.iconColor.withOpacity(0.25),
                  child: Center(
                    child: Icon(
                      slide.icon,
                      size: 96,
                      color: slide.iconColor,
                    ),
                  ),
                )
              : Image.asset(
                  slide.imageAsset,
                  key: Key('onboardingImage_$index'),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      key: Key('onboardingFallbackIcon_$index'),
                      color: slide.iconColor.withOpacity(0.25),
                      child: Center(
                        child: Icon(
                          slide.icon,
                          size: 96,
                          color: slide.iconColor,
                        ),
                      ),
                    );
                  },
                ),
        ),

        // 2. High-contrast Scrim Gradient Overlay for 100% text readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.20, 0.40, 0.62, 0.85, 1.0],
                colors: [
                  Colors.black.withOpacity(0.55), // Top scrim for top bar readability
                  Colors.black.withOpacity(0.15),
                  Colors.transparent,             // Clear mid area to view the graphic illustration
                  Colors.black.withOpacity(0.40), // Transition into text backdrop
                  Colors.black.withOpacity(0.85), // Solid dark backdrop for title/desc
                  Colors.black.withOpacity(0.95), // Deep dark for bottom controls
                ],
              ),
            ),
          ),
        ),

        // 3. Clear, High-Contrast Typography
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                children: [
                  const Spacer(flex: 5),

                  // Slide Title
                  Text(
                    loc.translate(slide.titleKey),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.2,
                      height: 1.25,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Slide Description
                  Text(
                    loc.translate(slide.descKey),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.90),
                      height: 1.5,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 110), // Room for dots + action button
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
