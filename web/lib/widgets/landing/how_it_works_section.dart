import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.xxl * 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Column(
        children: [
          // Section Header
          Text(
            'How It Works',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          Text(
            'Simple steps to start your Sharia-compliant investment journey',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: AppSizes.xxl),
          
          // Steps
          LayoutBuilder(
            builder: (context, constraints) {
              return constraints.maxWidth > 768
                ? _buildHorizontalSteps()
                : _buildVerticalSteps();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSteps() {
    return Row(
      children: [
        Expanded(child: _buildStep(1, 'Join Cooperative', 'Become a member of a registered cooperative to access investment opportunities.', Icons.people)),
        _buildStepConnector(),
        Expanded(child: _buildStep(2, 'Browse Projects', 'Explore vetted business projects within your cooperative network.', Icons.search)),
        _buildStepConnector(),
        Expanded(child: _buildStep(3, 'Invest Securely', 'Make investments through our secure platform with transparent terms.', Icons.security)),
        _buildStepConnector(),
        Expanded(child: _buildStep(4, 'Earn Profits', 'Receive profit distributions based on Sharia-compliant principles.', Icons.trending_up)),
      ],
    );
  }

  Widget _buildVerticalSteps() {
    return Column(
      children: [
        _buildStep(1, 'Join Cooperative', 'Become a member of a registered cooperative to access investment opportunities.', Icons.people),
        const SizedBox(height: AppSizes.xl),
        _buildStep(2, 'Browse Projects', 'Explore vetted business projects within your cooperative network.', Icons.search),
        const SizedBox(height: AppSizes.xl),
        _buildStep(3, 'Invest Securely', 'Make investments through our secure platform with transparent terms.', Icons.security),
        const SizedBox(height: AppSizes.xl),
        _buildStep(4, 'Earn Profits', 'Receive profit distributions based on Sharia-compliant principles.', Icons.trending_up),
      ],
    );
  }

  Widget _buildStep(int number, String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        children: [
          // Step Number
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: AppTextStyles.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          // Icon
          Icon(
            icon,
            size: 40,
            color: AppColors.primary,
          ),
          
          const SizedBox(height: AppSizes.md),
          
          // Title
          Text(
            title,
            style: AppTextStyles.h5.copyWith(
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: AppSizes.sm),
          
          // Description
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return Container(
      width: 60,
      height: 2,
      color: AppColors.primary.withOpacity(0.3),
    );
  }
}
