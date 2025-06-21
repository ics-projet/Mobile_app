// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/sms_gateway_settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const SMSGatewayApp());
}

class SMSGatewayApp extends StatelessWidget {
  const SMSGatewayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Gateway',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Segoe UI',
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => DashboardScreen(username: args['username']),
          );
        } else if (settings.name == '/logs') {
          final args = settings.arguments;
          if (args != null && args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (context) => LogsScreen(username: args['username']),
            );
          } else {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Missing or invalid arguments for /logs')),
              ),
            );
          }
        } else if (settings.name == '/settings') {
          final args = settings.arguments;
          if (args != null && args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (context) => SMSGatewaySettingsScreen(username: args['username']),
            );
          } else {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('Missing or invalid arguments for /settings')),
              ),
            );
          }
        }

        // Optional: handle unknown routes
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Unknown route')),
          ),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}