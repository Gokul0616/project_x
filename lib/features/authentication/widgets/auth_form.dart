import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_x/core/constants/route_constants.dart';
import 'package:project_x/core/theme/color_palette.dart';
import 'package:provider/provider.dart';
import 'package:project_x/core/constants/app_constants.dart';
import 'package:project_x/core/constants/asset_constants.dart';
import 'package:project_x/core/theme/text_styles.dart';
import 'package:project_x/features/authentication/auth_viewmodel.dart';
import 'package:project_x/shared/widgets/custom_text_field.dart';
import 'package:project_x/shared/widgets/loading_indicator.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;

  const AuthForm({super.key, required this.isLogin});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();
  final _focusUsername = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _focusEmail.dispose();
    _focusPassword.dispose();
    _focusUsername.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    if (widget.isLogin) {
      await authViewModel.login(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      await authViewModel.signup(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            widget.isLogin ? 'Log in to X' : 'Join X today',
            style: TextStyles.displayLarge,
          ),

          const SizedBox(height: AppConstants.paddingXL),

          // Error message
          if (authViewModel.errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
              ),
              child: Text(
                authViewModel.errorMessage,
                style: TextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),

          if (authViewModel.errorMessage.isNotEmpty)
            const SizedBox(height: AppConstants.paddingM),

          // Email field
          CustomTextField(
            controller: _emailController,
            focusNode: _focusEmail,
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email, color: AppColors.midGray),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (widget.isLogin) {
                _focusPassword.requestFocus();
              } else {
                _focusUsername.requestFocus();
              }
            },
          ),

          const SizedBox(height: AppConstants.paddingM),

          // Username field (only for signup)
          if (!widget.isLogin) ...[
            CustomTextField(
              controller: _usernameController,
              focusNode: _focusUsername,
              labelText: 'Username',
              prefixIcon: const Icon(Icons.person, color: AppColors.midGray),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please choose a username';
                }
                if (value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                _focusPassword.requestFocus();
              },
            ),
            const SizedBox(height: AppConstants.paddingM),
          ],

          // Password field
          CustomTextField(
            controller: _passwordController,
            focusNode: _focusPassword,
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock, color: AppColors.midGray),
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: AppColors.midGray,
              ),
              onPressed: _togglePasswordVisibility,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              _submitForm();
            },
          ),

          const SizedBox(height: AppConstants.paddingM),

          // Forgot password (only for login)
          if (widget.isLogin) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, RouteConstants.forgotPassword);
                },
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
          ],

          // Submit button
          ElevatedButton(
            onPressed: authViewModel.isLoading ? null : _submitForm,
            child: authViewModel.isLoading
                ? const LoadingIndicator(size: 20)
                : Text(widget.isLogin ? 'Log in' : 'Sign up'),
          ),

          const SizedBox(height: AppConstants.paddingXL),

          // Or divider
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingM,
                ),
                child: Text('Or'),
              ),
              Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: AppConstants.paddingXL),

          // Social login buttons
          OutlinedButton.icon(
            onPressed: () {
              // Google sign in logic
            },
            icon: SvgPicture.asset(
              AssetConstants.iconGoogle,
              width: 24,
              height: 24,
            ),
            label: const Text('Continue with Google'),
          ),

          const SizedBox(height: AppConstants.paddingM),

          OutlinedButton.icon(
            onPressed: () {
              // Apple sign in logic
            },
            icon: SvgPicture.asset(
              AssetConstants.iconApple,
              width: 24,
              height: 24,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.white
                  : AppColors.black,
            ),
            label: const Text('Continue with Apple'),
          ),

          const SizedBox(height: AppConstants.paddingXL),

          // Sign up / Login redirect
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isLogin
                    ? "Don't have an account?"
                    : "Already have an account?",
                style: TextStyles.bodySmall,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    widget.isLogin
                        ? RouteConstants.signup
                        : RouteConstants.login,
                  );
                },
                child: Text(widget.isLogin ? 'Sign up' : 'Log in'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
