import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/project_provider.dart';
import 'providers/investment_provider.dart';
import 'providers/cooperative_provider.dart';
import 'utils/constants.dart';

void main() {
  runApp(const ComFundsApp());
}

class ComFundsApp extends StatelessWidget {
  const ComFundsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => InvestmentProvider()),
        ChangeNotifierProvider(create: (_) => CooperativeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: const Locale('id', 'ID'),
            supportedLocales: const [
              Locale('id', 'ID'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const App(),
          );
        },
      ),
    );
  }
}
