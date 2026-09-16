import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppConstants.primaryGreen,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryGreen,
        primary: AppConstants.primaryGreen,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppConstants.primaryGreen,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppConstants.primaryGreen;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppConstants.primaryGreen.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.3);
        }),
      ),
    );
  }
}
