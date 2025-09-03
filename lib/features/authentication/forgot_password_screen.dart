import 'package:flutter/material.dart';
import 'package:project_x/core/theme/color_palette.dart';
import 'package:provider/provider.dart';
import 'package:project_x/core/constants/app_constants.dart';
import 'package:project_x/core/theme/text_styles.dart';
import 'package:project_x/features/authentication/auth_viewmodel.dart';
import 'package:project_x/shared/widgets/custom_text_field.dart';
import 'package:project_x/shared/widgets/loading_indicator.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    await authViewModel.forgotPassword(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your email address to reset your password',
                style: TextStyles.bodyLarge,
              ),
              const SizedBox(height: AppConstants.paddingXL),
              
              // Error message
              if (authViewModel.errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: authViewModel.errorMessage.contains('sent') 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                  ),
                  child: Text(
                    authViewModel.errorMessage,
                    style: TextStyles.bodySmall.copyWith(
                      color: authViewModel.errorMessage.contains('sent') 
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
              
              if (authViewModel.errorMessage.isNotEmpty)
                const SizedBox(height: AppConstants.paddingM),
              
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
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
              ),
              const SizedBox(height: AppConstants.paddingXL),
              ElevatedButton(
                onPressed: authViewModel.isLoading ? null : _submit,
                child: authViewModel.isLoading 
                    ? const LoadingIndicator(size: 20)
                    : const Text('Reset Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}