import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.xxl * 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
      ),
      child: Column(
        children: [
          // Section Header
          Text(
            'What Our Members Say',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          Text(
            'Hear from cooperative members who have successfully invested through our platform',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: AppSizes.xxl),
          
          // Testimonials Grid
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: constraints.maxWidth > 1200 ? 3 : 
                               constraints.maxWidth > 768 ? 2 : 1,
                crossAxisSpacing: AppSizes.lg,
                mainAxisSpacing: AppSizes.lg,
                childAspectRatio: constraints.maxWidth > 768 ? 1.5 : 1.8,
                children: const [
                  TestimonialCard(
                    name: 'Ahmad Rahman',
                    role: 'Cooperative Member',
                    cooperative: 'Koperasi Sejahtera',
                    testimonial: 'ComFunds has transformed how I invest. The transparency and Sharia compliance give me peace of mind. I\'ve earned consistent returns while supporting local businesses.',
                    rating: 5,
                    avatar: 'A',
                  ),
                  TestimonialCard(
                    name: 'Siti Nurhaliza',
                    role: 'Business Owner',
                    cooperative: 'Koperasi Mandiri',
                    testimonial: 'As a business owner, getting funding through ComFunds was seamless. The cooperative network provided not just capital but also valuable business connections.',
                    rating: 5,
                    avatar: 'S',
                  ),
                  TestimonialCard(
                    name: 'Budi Santoso',
                    role: 'Investor',
                    cooperative: 'Koperasi Maju',
                    testimonial: 'The platform is user-friendly and the profit-sharing model is fair. I can track my investments in real-time and the returns have exceeded my expectations.',
                    rating: 5,
                    avatar: 'B',
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: AppSizes.xxl),
          
          // Stats Section
          Container(
            padding: const EdgeInsets.all(AppSizes.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              boxShadow: AppShadows.medium,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStat('4.9/5', 'Average Rating', Icons.star),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: AppColors.textDisabled.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStat('98%', 'Satisfaction Rate', Icons.thumb_up),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: AppColors.textDisabled.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStat('15%', 'Average Returns', Icons.trending_up),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 30,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class TestimonialCard extends StatelessWidget {
  final String name;
  final String role;
  final String cooperative;
  final String testimonial;
  final int rating;
  final String avatar;

  const TestimonialCard({
    super.key,
    required this.name,
    required this.role,
    required this.cooperative,
    required this.testimonial,
    required this.rating,
    required this.avatar,
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
          // Rating
          Row(
            children: List.generate(5, (index) => Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: AppColors.secondary,
              size: 20,
            )),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          // Testimonial
          Expanded(
            child: Text(
              '"$testimonial"',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          const SizedBox(height: AppSizes.lg),
          
          // Author Info
          Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatar,
                    style: AppTextStyles.h5.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: AppSizes.md),
              
              // Author Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      role,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      cooperative,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
