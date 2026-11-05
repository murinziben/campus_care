import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Show a leftover error (e.g. rejected non-ALU account) only once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // On success AuthGate swaps this whole flow out, so nothing else to do.
    await context.read<AuthProvider>().signIn(_email.text, _password.text);
  }

  Future<void> _forgotPassword() async {
    final auth = context.read<AuthProvider>();
    final emailError = Validators.aluEmail(_email.text);
    if (emailError != null) {
      showSnack(context, 'Enter your ALU email above first.');
      return;
    }
    final ok = await auth.sendPasswordReset(_email.text);
    if (!mounted) return;
    showSnack(context,
        ok ? 'Password reset email sent.' : (auth.error ?? 'Could not send email.'));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Column(
        children: [
          const BrandHeader(showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome Back',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest)),
                    const SizedBox(height: 2),
                    const Text('Sign in to CampusCare', style: AppText.h1),
                    const SizedBox(height: 6),
                    const Text(
                        'Use your verified university account to continue.',
                        style: AppText.body),
                    const SizedBox(height: 22),
                    AppTextField(
                      label: 'ALU email',
                      hint: 'name@${AppConstants.studentDomain}',
                      controller: _email,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.aluEmail,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      controller: _password,
                      obscure: true,
                      icon: Icons.lock_outline_rounded,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: Validators.loginPassword,
                      onSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: auth.isBusy ? null : _forgotPassword,
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    if (auth.error != null) ...[
                      InlineMessage(message: auth.error!),
                      const SizedBox(height: 12),
                    ],
                    PrimaryButton(
                      label: 'Sign In',
                      icon: Icons.arrow_forward_rounded,
                      loading: auth.isBusy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_outlined,
                              size: 22, color: AppColors.forest),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'A verified ALU email is required to keep our '
                              'campus community secure.',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.deepGreen,
                                  height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('New to CampusCare?', style: AppText.muted),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/register'),
                          child: const Text('Create an account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
