import 'package:flutter/material.dart';
import 'package:project_x/core/constants/app_constants.dart';
import 'package:project_x/core/utils/responsive_utils.dart';
import 'package:project_x/features/authentication/widgets/auth_form.dart';
import 'package:project_x/features/authentication/widgets/auth_side_panel.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For large screens, use split layout
    if (ResponsiveUtils.isLargeScreen(context)) {
      return Scaffold(
        body: Row(
          children: [
            // Side panel
            Expanded(
              child: AuthSidePanel(
                title: 'See what\'s happening in the world right now',
                description: 'Join X today.',
              ),
            ),

            // Form area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingXL),
                child: AuthForm(isLogin: true),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingXL),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [AuthForm(isLogin: true)],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
