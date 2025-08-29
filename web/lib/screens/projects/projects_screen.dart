import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: AppSizes.lg),
            Text(
              'Projects Screen',
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
