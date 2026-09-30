import 'package:flutter/material.dart';

import 'package:uniandes_food/screens/auth/auth_form_fields.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/viewmodels/auth_view_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);

    await widget.viewModel.signUp(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
    );

    if (widget.viewModel.isAuthenticated) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final viewModel = widget.viewModel;

        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: AutofillGroup(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      tooltip: 'Back',
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.shadowGrey,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create account', style: AppText.h1),
                        const SizedBox(height: 8),
                        Text(
                          'Only @uniandes.edu.co emails can join, so every '
                          'review comes from the campus community.',
                          style: AppText.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        AuthTextField(
                          label: 'Full name',
                          controller: _nameController,
                          hint: 'María Ramírez',
                          keyboardType: TextInputType.name,
                          autofillHints: const [AutofillHints.name],
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Institutional email',
                          controller: _emailController,
                          hint: 'name@uniandes.edu.co',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Password',
                          controller: _passwordController,
                          hint: 'At least 6 characters',
                          obscure: true,
                          autofillHints: const [AutofillHints.newPassword],
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Confirm password',
                          controller: _confirmController,
                          obscure: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                        if (viewModel.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          AuthErrorMessage(message: viewModel.errorMessage!),
                        ],
                        const SizedBox(height: 24),
                        AuthSubmitButton(
                          label: 'Create account',
                          loading: viewModel.isLoading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
