import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/common/app_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.xl),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${user.name}!',
                        style: AppTextStyles.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        'Ready to explore investment opportunities?',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSizes.xl),
                
                // Quick Actions
                Text(
                  'Quick Actions',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSizes.lg,
                  mainAxisSpacing: AppSizes.lg,
                  childAspectRatio: 1.5,
                  children: [
                    _buildActionCard(
                      context,
                      'Browse Projects',
                      Icons.search,
                      AppColors.primary,
                      () => Navigator.pushNamed(context, '/projects'),
                    ),
                    _buildActionCard(
                      context,
                      'My Investments',
                      Icons.trending_up,
                      AppColors.success,
                      () => Navigator.pushNamed(context, '/investments'),
                    ),
                    _buildActionCard(
                      context,
                      'Profile',
                      Icons.person,
                      AppColors.accent,
                      () => Navigator.pushNamed(context, '/profile'),
                    ),
                    _buildActionCard(
                      context,
                      'Support',
                      Icons.help,
                      AppColors.secondary,
                      () {},
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSizes.xl),
                
                // User Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Information',
                          style: AppTextStyles.h5.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        _buildInfoRow('Name', user.name),
                        _buildInfoRow('Email', user.email),
                        if (user.phone != null) _buildInfoRow('Phone', user.phone!),
                        _buildInfoRow('Roles', user.roles.join(', ')),
                        _buildInfoRow('KYC Status', user.kycStatus),
                        const SizedBox(height: AppSizes.lg),
                        AppButton(
                          text: 'Logout',
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

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const SizedBox(height: AppSizes.md),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
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

  void _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}
