import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Investments'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppSizes.lg),
            Text(
              'Investments Screen',
              style: AppTextStyles.h4,
            ),
            SizedBox(height: AppSizes.md),
            Text(
              'Coming soon...',
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
