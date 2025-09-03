// import 'package:flutter/material.dart';
// import 'package:project_x/core/constants/asset_constants.dart';
// import 'package:project_x/core/theme/color_palette.dart';
// import 'package:project_x/features/home/home_screen.dart';
// import 'package:project_x/shared/services/navigation_service.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:project_x/core/constants/app_constants.dart';
// import 'package:project_x/core/constants/route_constants.dart';
// import 'package:project_x/core/theme/app_theme.dart';
// import 'package:project_x/features/authentication/auth_viewmodel.dart';
// import 'package:project_x/features/onboarding/onboarding_viewmodel.dart';
// import 'package:project_x/features/authentication/forgot_password_screen.dart';
// import 'package:project_x/features/authentication/login_screen.dart';
// import 'package:project_x/features/authentication/signup_screen.dart';
// import 'package:project_x/features/onboarding/onboarding_screen.dart';

// // Updated SplashScreen with navigation logic
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _navigateToNextScreen();
//   }

//   Future<void> _navigateToNextScreen() async {
//     await Future.delayed(const Duration(seconds: 2)); // Simulate loading time

//     final prefs = await SharedPreferences.getInstance();
//     final hasSeenOnboarding =
//         prefs.getBool(AppConstants.hasSeenOnboardingKey) ?? false;
//     final isLoggedIn = prefs.getString(AppConstants.authTokenKey) != null;

//     // ignore: use_build_context_synchronously
//     if (!hasSeenOnboarding) {
//       Navigator.pushReplacementNamed(context, RouteConstants.onboarding);
//     } else if (!isLoggedIn) {
//       Navigator.pushReplacementNamed(context, RouteConstants.login);
//     } else {
//       Navigator.pushReplacementNamed(context, RouteConstants.home);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // App logo
//             Image.asset(AssetConstants.logo, width: 80, height: 80),
//             const SizedBox(height: 20),
//             // Loading indicator
//             const CircularProgressIndicator(color: AppColors.blue),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Placeholder HomeScreen
// // class HomeScreen extends StatelessWidget {
// //   const HomeScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Home'),
// //         actions: [
// //           IconButton(
// //             icon: const Icon(Icons.logout),
// //             onPressed: () async {
// //               final prefs = await SharedPreferences.getInstance();
// //               await prefs.remove(AppConstants.authTokenKey);
// //               Navigator.pushReplacementNamed(context, RouteConstants.login);
// //             },
// //           ),
// //         ],
// //       ),
// //       body: const Center(child: Text('Welcome to X Clone!')),
// //     );
// //   }
// // }

// class NotFoundScreen extends StatelessWidget {
//   const NotFoundScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Page Not Found')),
//       body: const Center(child: Text('The requested page could not be found.')),
//     );
//   }
// }

// class XApp extends StatelessWidget {
//   const XApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthViewModel()),
//         ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
//       ],
//       child: MaterialApp(
//         title: 'X Clone',
//         debugShowCheckedModeBanner: false,
//         theme: AppTheme.darkTheme,
//         navigatorKey: NavigationService.navigatorKey,
//         initialRoute: RouteConstants.splash,
//         onGenerateRoute: (settings) {
//           switch (settings.name) {
//             case RouteConstants.splash:
//               return MaterialPageRoute(builder: (_) => const SplashScreen());
//             case RouteConstants.onboarding:
//               return MaterialPageRoute(
//                 builder: (_) => const OnboardingScreen(),
//               );
//             case RouteConstants.login:
//               return MaterialPageRoute(builder: (_) => const LoginScreen());
//             case RouteConstants.signup:
//               return MaterialPageRoute(builder: (_) => const SignupScreen());
//             case RouteConstants.home:
//               return MaterialPageRoute(builder: (_) => const HomeScreen());
//             case RouteConstants.forgotPassword:
//               return MaterialPageRoute(
//                 builder: (_) => const ForgotPasswordScreen(),
//               );
//             default:
//               return MaterialPageRoute(builder: (_) => const NotFoundScreen());
//           }
//         },
//         builder: (context, child) {
//           return MediaQuery(
//             data: MediaQuery.of(context).copyWith(
//               textScaler: TextScaler.linear(
//                 MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
//               ),
//             ),
//             child: child!,
//           );
//         },
//       ),
//     );
//   }
// }

// lib/app.dart
import 'package:flutter/material.dart';
import 'package:project_x/core/constants/asset_constants.dart';
import 'package:project_x/core/constants/route_constants.dart';
import 'package:project_x/core/theme/app_theme.dart';
import 'package:project_x/core/theme/color_palette.dart';
import 'package:project_x/features/authentication/auth_viewmodel.dart';
import 'package:project_x/features/authentication/forgot_password_screen.dart';
import 'package:project_x/features/authentication/login_screen.dart';
import 'package:project_x/features/authentication/signup_screen.dart';
import 'package:project_x/features/home/home_screen.dart';
import 'package:project_x/features/home/home_viewmodel.dart'; // Add this import
import 'package:project_x/features/onboarding/onboarding_screen.dart';
import 'package:project_x/features/onboarding/onboarding_viewmodel.dart';
import 'package:project_x/shared/services/navigation_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_x/core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding =
        prefs.getBool(AppConstants.hasSeenOnboardingKey) ?? false;
    final isLoggedIn = prefs.getString(AppConstants.authTokenKey) != null;

    if (!hasSeenOnboarding) {
      Navigator.pushReplacementNamed(context, RouteConstants.onboarding);
    } else if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, RouteConstants.login);
    } else {
      Navigator.pushReplacementNamed(context, RouteConstants.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AssetConstants.logo, width: 80, height: 80),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppColors.blue),
          ],
        ),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(child: Text('The requested page could not be found.')),
    );
  }
}

class XApp extends StatelessWidget {
  const XApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(),
        ), // Add HomeViewModel
      ],
      child: MaterialApp(
        title: 'X Clone',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        navigatorKey: NavigationService.navigatorKey,
        initialRoute: RouteConstants.splash,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case RouteConstants.splash:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case RouteConstants.onboarding:
              return MaterialPageRoute(
                builder: (_) => const OnboardingScreen(),
              );
            case RouteConstants.login:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case RouteConstants.signup:
              return MaterialPageRoute(builder: (_) => const SignupScreen());
            case RouteConstants.home:
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              ); // Line 137
            // In XApp's onGenerateRoute
            // case RouteConstants.search:
            //   return MaterialPageRoute(builder: (_) => const SearchScreen()); // Define SearchScreen
            // case RouteConstants.notifications:
            //   return MaterialPageRoute(builder: (_) => const NotificationsScreen()); // Define NotificationsScreen
            // case RouteConstants.messages:
            //   return MaterialPageRoute(builder: (_) => const MessagesScreen()); // Define MessagesScreen
            // case RouteConstants.profile:
            //   return MaterialPageRoute(builder: (_) => const ProfileScreen()); // Define ProfileScreen
            case RouteConstants.forgotPassword:
              return MaterialPageRoute(
                builder: (_) => const ForgotPasswordScreen(),
              );
            default:
              return MaterialPageRoute(builder: (_) => const NotFoundScreen());
          }
        },
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
