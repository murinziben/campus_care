import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // On success the auth state becomes "unverified" and AuthGate shows the
    // verification screen.
    await context
        .read<AuthProvider>()
        .register(_name.text, _email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pw = _password.text;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const LogoLockup(compact: true),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('JOIN THE COMMUNITY', style: AppText.eyebrow),
                const SizedBox(height: 8),
                const Text('Create your account', style: AppText.h1),
                const SizedBox(height: 8),
                const Text(
                  'Your reports help make campus safer and better for everyone.',
                  style: AppText.body,
                ),
                const SizedBox(height: 22),
                AppTextField(
                  label: 'Full name',
                  hint: 'e.g. Amara Mensah',
                  controller: _name,
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 14),
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
                  hint: 'Create a password',
                  controller: _password,
                  obscure: true,
                  icon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Rule(
                        text: '${AppConstants.minPasswordLength}+ characters',
                        ok: Validators.hasMinLength(pw)),
                    const SizedBox(width: 14),
                    _Rule(text: 'One number', ok: Validators.hasNumber(pw)),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Confirm password',
                  hint: 'Repeat your password',
                  controller: _confirm,
                  obscure: true,
                  icon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.confirmPassword(v, _password.text),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                if (auth.error != null) ...[
                  InlineMessage(message: auth.error!),
                  const SizedBox(height: 12),
                ],
                PrimaryButton(
                  label: 'Create Account',
                  loading: auth.isBusy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?', style: AppText.muted),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text, required this.ok});
  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.green : AppColors.slate400;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
