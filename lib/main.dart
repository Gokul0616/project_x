import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/tweet_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/upload_provider.dart';
import 'providers/message_provider.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService.initialize();
  
  runApp(const PulseApp());
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TweetProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => UploadProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Pulse',
            theme: themeProvider.currentTheme,
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}