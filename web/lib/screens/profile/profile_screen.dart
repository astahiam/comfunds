import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/common/app_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.xl),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: AppTextStyles.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        
                        // Name
                        Text(
                          user.name,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        
                        // Email
                        Text(
                          user.email,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        
                        // KYC Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.sm,
                          ),
                          decoration: BoxDecoration(
                            color: user.kycStatus == 'verified' 
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                            border: Border.all(
                              color: user.kycStatus == 'verified' 
                                ? AppColors.success
                                : AppColors.warning,
                            ),
                          ),
                          child: Text(
                            'KYC: ${user.kycStatus.toUpperCase()}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: user.kycStatus == 'verified' 
                                ? AppColors.success
                                : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSizes.xl),
                
                // Profile Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Details',
                          style: AppTextStyles.h5.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        _buildDetailRow('Name', user.name),
                        _buildDetailRow('Email', user.email),
                        if (user.phone != null) _buildDetailRow('Phone', user.phone!),
                        if (user.address != null) _buildDetailRow('Address', user.address!),
                        _buildDetailRow('Roles', user.roles.join(', ')),
                        _buildDetailRow('Member Since', _formatDate(user.createdAt)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSizes.xl),
                
                // Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actions',
                          style: AppTextStyles.h5.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        AppButton(
                          text: 'Edit Profile',
                          icon: Icons.edit,
                          onPressed: () {},
                          isFullWidth: true,
                        ),
                        const SizedBox(height: AppSizes.md),
                        AppButton(
                          text: 'Change Password',
                          icon: Icons.lock,
                          variant: ButtonVariant.outlined,
                          onPressed: () {},
                          isFullWidth: true,
                        ),
                        const SizedBox(height: AppSizes.md),
                        AppButton(
                          text: 'Logout',
                          icon: Icons.logout,
                          variant: ButtonVariant.outlined,
                          onPressed: () => _handleLogout(context),
                          isFullWidth: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}
