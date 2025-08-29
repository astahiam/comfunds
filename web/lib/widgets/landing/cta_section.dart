import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../common/app_button.dart';

class CTASection extends StatelessWidget {
  const CTASection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.xxl * 2,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryGradient,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            child: Column(
              children: [
                // Main Content
                Text(
                  'Ready to Start Your Investment Journey?',
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white,
                    fontSize: constraints.maxWidth > 768 ? 36 : 28,
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: AppSizes.lg),
                
                Text(
                  'Join thousands of cooperative members who are already building wealth through Sharia-compliant investments. Start today and be part of the future of cooperative financing.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: constraints.maxWidth > 768 ? 18 : 16,
                    textAlign: TextAlign.center,
                    height: 1.6,
                  ),
                ),
                
                const SizedBox(height: AppSizes.xl),
                
                // CTA Buttons
                Wrap(
                  spacing: AppSizes.md,
                  runSpacing: AppSizes.md,
                  alignment: WrapAlignment.center,
                  children: [
                    AppButton(
                      text: 'Get Started Now',
                      size: ButtonSize.large,
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      backgroundColor: AppColors.secondary,
                      textStyle: AppTextStyles.buttonLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                
                const SizedBox(height: AppSizes.xl),
                
                // Trust Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTrustIndicator(Icons.security, 'Bank-level Security'),
                    const SizedBox(width: AppSizes.xl),
                    _buildTrustIndicator(Icons.verified_user, 'Regulated Platform'),
                    const SizedBox(width: AppSizes.xl),
                    _buildTrustIndicator(Icons.support_agent, '24/7 Support'),
                  ],
                ),
                
                const SizedBox(height: AppSizes.xl),
                
                // Additional Info
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Flexible(
                        child: Text(
                          'No setup fees • No hidden charges • 100% Sharia compliant',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrustIndicator(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(width: AppSizes.sm),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  void _scrollToFeatures(BuildContext context) {
    // Implementation for smooth scrolling to features section
  }
}
