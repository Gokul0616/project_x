import 'package:flutter/material.dart';
import 'package:project_x/core/constants/app_constants.dart';
import 'package:project_x/core/utils/responsive_utils.dart';
import 'package:project_x/features/authentication/widgets/auth_form.dart';
import 'package:project_x/features/authentication/widgets/auth_side_panel.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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
                title: 'Join the conversation',
                description:
                    'Sign up now to connect with people who share your interests.',
              ),
            ),

            // Form area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingXL),
                child: AuthForm(isLogin: false),
              ),
            ),
          ],
        ),
      );
    }

    // For mobile screens
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
                    children: const [AuthForm(isLogin: false)],
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
