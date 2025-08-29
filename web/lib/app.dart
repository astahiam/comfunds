import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/projects/projects_screen.dart';
import 'screens/investments/investments_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'utils/constants.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: Theme.of(context).copyWith(
            primarySwatch: Colors.green,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          initialRoute: authProvider.isAuthenticated ? '/dashboard' : '/',
          routes: {
            '/': (context) => const LandingScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/projects': (context) => const ProjectsScreen(),
            '/investments': (context) => const InvestmentsScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
        );
      },
    );
  }
}
