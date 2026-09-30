import 'package:flutter/material.dart';

import 'package:uniandes_food/screens/auth/auth_form_fields.dart';
import 'package:uniandes_food/screens/auth/register_screen.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/viewmodels/auth_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isPushed => !(ModalRoute.of(context)?.isFirst ?? true);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    final closeOnSuccess = _isPushed;

    await widget.viewModel.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (closeOnSuccess && widget.viewModel.isAuthenticated) navigator.pop();
  }

  Future<void> _openRegister() async {
    final navigator = Navigator.of(context);
    final closeOnSuccess = _isPushed;

    widget.viewModel.clearError();
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(viewModel: widget.viewModel),
      ),
    );
    widget.viewModel.clearError();

    if (closeOnSuccess && widget.viewModel.isAuthenticated) navigator.pop();
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
                padding: EdgeInsets.fromLTRB(24, _isPushed ? 8 : 40, 24, 24),
                children: [
                  if (_isPushed)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        tooltip: 'Close',
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.shadowGrey,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        size: 28,
                        color: AppColors.shadowGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Welcome back', style: AppText.h1),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with your Uniandes account to write reviews '
                    'and report wait times at campus spots.',
                    style: AppText.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
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
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                  ),
                  if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    AuthErrorMessage(message: viewModel.errorMessage!),
                  ],
                  const SizedBox(height: 24),
                  AuthSubmitButton(
                    label: 'Sign in',
                    loading: viewModel.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppText.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: viewModel.isLoading ? null : _openRegister,
                        child: const Text('Create one'),
                      ),
                    ],
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
