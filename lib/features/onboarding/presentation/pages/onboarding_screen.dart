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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final langCode = context.watch<LanguageProvider>().currentLocale.languageCode;

    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final dotInactiveColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: Skip + Language switcher ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  TextButton(
                    key: const Key('onboardingSkipButton'),
                    onPressed: _finishOnboarding,
                    child: Text(
                      loc.translate('onboarding_skip'),
                      style: TextStyle(
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Language toggle
                  OutlinedButton(
                    key: const Key('onboardingLanguageToggle'),
                    onPressed: _toggleLanguage,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: colorScheme.primary.withOpacity(0.6),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      langCode == 'en' ? 'EN | VI' : 'VI | EN',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Page View (slides) ──────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                key: const Key('onboardingPageView'),
                controller: _pageController,
                itemCount: OnboardingScreen.slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildSlide(
                    context,
                    OnboardingScreen.slides[index],
                    index,
                    loc,
                    textColor,
                    subtitleColor,
                    isDark,
                  );
                },
              ),
            ),

            // ── Dot indicator ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(OnboardingScreen.slides.length, (i) {
                  final isActive = _currentPage == i;
                  return AnimatedContainer(
                    key: Key('onboardingDot_$i'),
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? colorScheme.primary : dotInactiveColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // ── Bottom buttons ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
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
                          elevation: 3,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(
    BuildContext context,
    OnboardingSlide slide,
    int index,
    AppLocalizations loc,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final imageHeight = (availableHeight * 0.52).clamp(180.0, 360.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Prominent Graphic Illustration Container
                  Container(
                    height: imageHeight,
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.showFallbackIcon
                        ? Container(
                            key: Key('onboardingFallbackIcon_$index'),
                            color: slide.iconColor.withOpacity(0.12),
                            child: Center(
                              child: Icon(
                                slide.icon,
                                size: 80,
                                color: slide.iconColor,
                              ),
                            ),
                          )
                        : Image.asset(
                            slide.imageAsset,
                            key: Key('onboardingImage_$index'),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                key: Key('onboardingFallbackIcon_$index'),
                                color: slide.iconColor.withOpacity(0.12),
                                child: Center(
                                  child: Icon(
                                    slide.icon,
                                    size: 80,
                                    color: slide.iconColor,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 28),

                  // Title
                  Text(
                    loc.translate(slide.titleKey),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    loc.translate(slide.descKey),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: subtitleColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
