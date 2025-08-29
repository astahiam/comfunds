import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.xxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Main Footer Content
              if (constraints.maxWidth > 768)
                _buildDesktopFooter()
              else
                _buildMobileFooter(),
              
              const SizedBox(height: AppSizes.xl),
              
              // Divider
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              
              const SizedBox(height: AppSizes.lg),
              
              // Bottom Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2024 ComFunds. All rights reserved.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  if (constraints.maxWidth > 768)
                    Row(
                      children: [
                        _buildFooterLink('Privacy Policy', () {}),
                        const SizedBox(width: AppSizes.lg),
                        _buildFooterLink('Terms of Service', () {}),
                        const SizedBox(width: AppSizes.lg),
                        _buildFooterLink('Cookie Policy', () {}),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopFooter() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company Info
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: AppTextStyles.h4.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                AppConstants.appDescription,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              _buildSocialLinks(),
            ],
          ),
        ),
        
        const SizedBox(width: AppSizes.xl),
        
        // Quick Links
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Links',
                style: AppTextStyles.h6.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              _buildFooterLink('About Us', () {}),
              _buildFooterLink('How It Works', () {}),
              _buildFooterLink('Features', () {}),
              _buildFooterLink('Pricing', () {}),
              _buildFooterLink('Blog', () {}),
            ],
          ),
        ),
        
        const SizedBox(width: AppSizes.xl),
        
        // Support
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support',
                style: AppTextStyles.h6.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              _buildFooterLink('Help Center', () {}),
              _buildFooterLink('Contact Us', () {}),
              _buildFooterLink('FAQ', () {}),
              _buildFooterLink('Community', () {}),
              _buildFooterLink('Status', () {}),
            ],
          ),
        ),
        
        const SizedBox(width: AppSizes.xl),
        
        // Contact Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact',
                style: AppTextStyles.h6.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              _buildContactInfo(Icons.email, AppConstants.contactEmail),
              _buildContactInfo(Icons.phone, AppConstants.contactPhone),
              _buildContactInfo(Icons.location_on, AppConstants.contactAddress),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company Info
        Text(
          AppConstants.appName,
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Text(
          AppConstants.appDescription,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.7),
            height: 1.6,
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        _buildSocialLinks(),
        const SizedBox(height: AppSizes.xl),
        
        // Quick Links
        _buildMobileSection('Quick Links', [
          'About Us',
          'How It Works',
          'Features',
          'Pricing',
          'Blog',
        ]),
        
        const SizedBox(height: AppSizes.lg),
        
        // Support
        _buildMobileSection('Support', [
          'Help Center',
          'Contact Us',
          'FAQ',
          'Community',
          'Status',
        ]),
        
        const SizedBox(height: AppSizes.lg),
        
        // Contact
        Text(
          'Contact',
          style: AppTextStyles.h6.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        _buildContactInfo(Icons.email, AppConstants.contactEmail),
        _buildContactInfo(Icons.phone, AppConstants.contactPhone),
        _buildContactInfo(Icons.location_on, AppConstants.contactAddress),
      ],
    );
  }

  Widget _buildMobileSection(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h6.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: _buildFooterLink(link, () {}),
        )),
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Row(
      children: [
        _buildSocialLink(Icons.facebook, AppConstants.facebookUrl),
        const SizedBox(width: AppSizes.md),
        _buildSocialLink(Icons.twitter, AppConstants.twitterUrl),
        const SizedBox(width: AppSizes.md),
        _buildSocialLink(Icons.instagram, AppConstants.instagramUrl),
        const SizedBox(width: AppSizes.md),
        _buildSocialLink(Icons.linkedin, AppConstants.linkedinUrl),
      ],
    );
  }

  Widget _buildSocialLink(IconData icon, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.7),
            size: 16,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
