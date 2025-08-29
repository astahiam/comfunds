import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../common/app_button.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryGradient,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 1200 
                ? AppSizes.xxl * 2 
                : AppSizes.xl,
              vertical: AppSizes.xxl * 2,
            ),
            child: Row(
              children: [
                // Left Content
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          border: Border.all(
                            color: AppColors.secondary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: AppColors.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              'Sharia-Compliant Platform',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSizes.xl),
                      
                      // Main Heading
                      Text(
                        'Empower Your Community\nThrough Halal Investments',
                        style: AppTextStyles.h1.copyWith(
                          color: Colors.white,
                          fontSize: constraints.maxWidth > 768 ? 48 : 36,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      
                      const SizedBox(height: AppSizes.lg),
                      
                      // Subheading
                      Text(
                        'Join thousands of cooperative members who are building wealth through transparent, Sharia-compliant profit-sharing investments. Connect with trusted business opportunities within your community.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: constraints.maxWidth > 768 ? 18 : 16,
                          height: 1.6,
                        ),
                      ),
                      
                      const SizedBox(height: AppSizes.xl),
                      
                      // Stats Row
                      Row(
                        children: [
                          _buildStat('10K+', 'Active Members'),
                          const SizedBox(width: AppSizes.xl),
                          _buildStat('500+', 'Projects Funded'),
                          const SizedBox(width: AppSizes.xl),
                          _buildStat('15%', 'Avg. Returns'),
                        ],
                      ),
                      
                      const SizedBox(height: AppSizes.xl),
                      
                      // CTA Buttons
                      Row(
                        children: [
                          AppButton(
                            text: 'Start Investing',
                            size: ButtonSize.large,
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            backgroundColor: AppColors.secondary,
                            textStyle: AppTextStyles.buttonLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          AppButton(
                            text: 'Learn More',
                            size: ButtonSize.large,
                            variant: ButtonVariant.outlined,
                            onPressed: () => _scrollToFeatures(context),
                            textColor: Colors.white,
                            borderColor: Colors.white,
                            textStyle: AppTextStyles.buttonLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSizes.lg),
                      
                      // Trust Indicators
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Bank-level security',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: AppSizes.lg),
                          Icon(
                            Icons.verified_user,
                            color: Colors.white.withOpacity(0.8),
                            size: 20,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Regulated platform',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Right Content - Hero Image/Illustration
                if (constraints.maxWidth > 768) ...[
                  const SizedBox(width: AppSizes.xxl),
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 600,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        boxShadow: AppShadows.large,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Background Pattern
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: HeroPatternPainter(),
                                ),
                              ),
                              
                              // Main Illustration
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Investment Cards
                                    _buildInvestmentCard(
                                      'Eco Farm Project',
                                      'Rp 50.000.000',
                                      '85% Funded',
                                      AppColors.success,
                                    ),
                                    const SizedBox(height: AppSizes.md),
                                    _buildInvestmentCard(
                                      'Tech Startup',
                                      'Rp 100.000.000',
                                      '92% Funded',
                                      AppColors.accent,
                                    ),
                                    const SizedBox(height: AppSizes.md),
                                    _buildInvestmentCard(
                                      'Local Restaurant',
                                      'Rp 75.000.000',
                                      '78% Funded',
                                      AppColors.secondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentCard(String title, String amount, String progress, Color color) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            amount,
            style: AppTextStyles.h5.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: 0.85,
                  backgroundColor: AppColors.textDisabled,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                progress,
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _scrollToFeatures(BuildContext context) {
    // Implementation for smooth scrolling to features section
  }
}

class HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    // Draw grid pattern
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
