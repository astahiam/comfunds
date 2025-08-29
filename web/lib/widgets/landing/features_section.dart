import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.xxl * 2,
      ),
      child: Column(
        children: [
          // Section Header
          Text(
            'Why Choose ComFunds?',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          Text(
            'Experience the future of cooperative financing with our comprehensive platform designed for Sharia-compliant investments.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: AppSizes.xxl),
          
          // Features Grid
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: constraints.maxWidth > 1200 ? 4 : 
                               constraints.maxWidth > 768 ? 3 : 
                               constraints.maxWidth > 480 ? 2 : 1,
                crossAxisSpacing: AppSizes.lg,
                mainAxisSpacing: AppSizes.lg,
                childAspectRatio: constraints.maxWidth > 768 ? 1.2 : 1.5,
                children: const [
                  FeatureCard(
                    icon: Icons.verified_user,
                    title: 'Sharia Compliant',
                    description: 'All investments follow Islamic financial principles with transparent profit-sharing mechanisms.',
                    color: AppColors.halal,
                  ),
                  FeatureCard(
                    icon: Icons.security,
                    title: 'Secure & Regulated',
                    description: 'Bank-level security with regulatory compliance and comprehensive audit trails.',
                    color: AppColors.accent,
                  ),
                  FeatureCard(
                    icon: Icons.people,
                    title: 'Community Focused',
                    description: 'Built specifically for cooperatives to strengthen community bonds and local economies.',
                    color: AppColors.primary,
                  ),
                  FeatureCard(
                    icon: Icons.trending_up,
                    title: 'Transparent Returns',
                    description: 'Real-time tracking of investments with clear profit distribution and performance metrics.',
                    color: AppColors.success,
                  ),
                  FeatureCard(
                    icon: Icons.mobile_friendly,
                    title: 'Multi-Platform',
                    description: 'Access your investments anywhere with our web and mobile applications.',
                    color: AppColors.secondary,
                  ),
                  FeatureCard(
                    icon: Icons.analytics,
                    title: 'Smart Analytics',
                    description: 'Advanced analytics and insights to make informed investment decisions.',
                    color: AppColors.info,
                  ),
                  FeatureCard(
                    icon: Icons.support_agent,
                    title: '24/7 Support',
                    description: 'Dedicated support team to help you with any questions or concerns.',
                    color: AppColors.warning,
                  ),
                  FeatureCard(
                    icon: Icons.speed,
                    title: 'Fast Processing',
                    description: 'Quick project approval and fund disbursement processes.',
                    color: AppColors.accent,
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: AppSizes.xxl),
          
          // Additional Features
          Container(
            padding: const EdgeInsets.all(AppSizes.xl),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advanced Features',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      _buildFeatureList([
                        'Automated profit distribution',
                        'Real-time project monitoring',
                        'Multi-language support',
                        'Mobile-responsive design',
                        'API integration capabilities',
                        'Comprehensive reporting',
                      ]),
                    ],
                  ),
                ),
                if (MediaQuery.of(context).size.width > 768) ...[
                  const SizedBox(width: AppSizes.xl),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: const Icon(
                      Icons.rocket_launch,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(List<String> features) {
    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.sm),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                feature,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: AppShadows.small,
        border: Border.all(
          color: AppColors.textDisabled.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          // Title
          Text(
            title,
            style: AppTextStyles.h5.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppSizes.sm),
          
          // Description
          Expanded(
            child: Text(
              description,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
