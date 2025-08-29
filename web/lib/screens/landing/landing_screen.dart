import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/landing/hero_section.dart';
import '../../widgets/landing/features_section.dart';
import '../../widgets/landing/how_it_works_section.dart';
import '../../widgets/landing/testimonials_section.dart';
import '../../widgets/landing/cta_section.dart';
import '../../widgets/landing/footer_section.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _isScrolled = _scrollController.offset > 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 80,
            floating: false,
            pinned: true,
            backgroundColor: _isScrolled ? AppColors.primary : Colors.transparent,
            elevation: _isScrolled ? 4 : 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: _isScrolled 
                    ? null 
                    : AppGradients.primaryGradient,
                ),
              ),
            ),
            title: _isScrolled 
              ? Text(
                  AppConstants.appName,
                  style: AppTextStyles.h5.copyWith(color: Colors.white),
                )
              : null,
            actions: [
              if (!_isScrolled) ...[
                TextButton(
                  onPressed: () => _scrollToSection('features'),
                  child: const Text(
                    'Features',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () => _scrollToSection('how-it-works'),
                  child: const Text(
                    'How It Works',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () => _scrollToSection('about'),
                  child: const Text(
                    'About',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
              ],
              AppButton(
                text: 'Login',
                variant: ButtonVariant.outlined,
                onPressed: () => Navigator.pushNamed(context, '/login'),
                textColor: Colors.white,
                borderColor: Colors.white,
              ),
              const SizedBox(width: AppSizes.sm),
              AppButton(
                text: 'Get Started',
                onPressed: () => Navigator.pushNamed(context, '/register'),
                backgroundColor: AppColors.secondary,
              ),
              const SizedBox(width: AppSizes.md),
            ],
          ),
          
          // Hero Section
          const SliverToBoxAdapter(
            child: HeroSection(),
          ),
          
          // Features Section
          const SliverToBoxAdapter(
            child: FeaturesSection(),
          ),
          
          // How It Works Section
          const SliverToBoxAdapter(
            child: HowItWorksSection(),
          ),
          
          // Testimonials Section
          const SliverToBoxAdapter(
            child: TestimonialsSection(),
          ),
          
          // CTA Section
          const SliverToBoxAdapter(
            child: CTASection(),
          ),
          
          // Footer Section
          const SliverToBoxAdapter(
            child: FooterSection(),
          ),
        ],
      ),
    );
  }

  void _scrollToSection(String sectionId) {
    // Implementation for smooth scrolling to sections
    // This would be implemented with GlobalKey for each section
  }
}
