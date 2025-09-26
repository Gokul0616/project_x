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
import 'services/call_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService.initialize();

  // Initialize CallService
  final callService = CallService();
  await callService.initialize().catchError((error) {
    print('Failed to initialize CallService: $error');
    // Continue without call service for now
  });

  runApp(PulseApp(callService: callService));
}

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (BuildContext context) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (BuildContext context) => AuthProvider()),
        ChangeNotifierProvider<TweetProvider>(create: (BuildContext context) => TweetProvider()),
        ChangeNotifierProvider<NotificationProvider>(create: (BuildContext context) => NotificationProvider()),
        ChangeNotifierProvider<UploadProvider>(create: (BuildContext context) => UploadProvider()),
        ChangeNotifierProvider<MessageProvider>(create: (BuildContext context) => MessageProvider()),
        ChangeNotifierProvider<CallService>(create: (BuildContext context) => CallService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (BuildContext context, ThemeProvider themeProvider, Widget? child) {
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
      builder: (BuildContext context, AuthProvider authProvider, Widget? child) {
        if (authProvider.isAuthenticated) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
