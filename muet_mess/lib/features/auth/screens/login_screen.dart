import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/brand_widgets.dart';
import '../../../widgets/common/dialogs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_username.text, _password.text);
    if (!mounted) return;
    if (ok) {
      context.go(auth.isManager ? RouteNames.managerDashboard : RouteNames.studentHome);
    } else {
      showError(context, auth.error ?? 'Login failed');
    }
  }

  void _fillDemo(String username, String password) {
    setState(() {
      _username.text = username;
      _password.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: wide
          ? Row(children: [
              const Expanded(flex: 5, child: _BrandPanel()),
              Expanded(
                flex: 4,
                child: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(40), child: _formCard(context)))),
              ),
            ])
          : SingleChildScrollView(
              child: Column(children: [
                const SizedBox(
                  height: 230,
                  width: double.infinity,
                  child: _BrandPanel(compact: true),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), child: _formCard(context)),
              ]),
            ),
    );
  }

  Widget _formCard(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Welcome back', style: text.headlineSmall),
        const SizedBox(height: 4),
        Text('Log in with your mess username.', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(children: [
              TextFormField(
                controller: _username,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                keyboardType: TextInputType.text,
                validator: Validators.required,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) {
                  if (!auth.loading) _submit();
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: Validators.required,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Forgot your password? Ask your mess manager to reset it.',
                  style: text.bodySmall,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: auth.loading ? null : _submit,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: auth.loading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: scheme.onPrimary),
                          )
                        : const Text('Log in', key: ValueKey('label')),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(onPressed: () => context.push(RouteNames.registerStudent), child: const Text('Create account')),
          Text('•', style: text.bodySmall),
          TextButton(onPressed: () => context.push(RouteNames.registerManager), child: const Text('Manager registration')),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.science_outlined, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Demo accounts (development)', style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(
                avatar: const Icon(Icons.school_outlined, size: 18),
                label: Text('Student · ${AppConstants.demoStudentUsername}'),
                onPressed: () => _fillDemo(AppConstants.demoStudentUsername, AppConstants.demoStudentPassword),
              ),
              ActionChip(
                avatar: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: Text('Manager · ${AppConstants.demoManagerUsername}'),
                onPressed: () => _fillDemo(AppConstants.demoManagerUsername, AppConstants.demoManagerPassword),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final onHero = context.tokens.onHero;
    return BrandBackground(
      borderRadius: compact ? const BorderRadius.vertical(bottom: Radius.circular(32)) : BorderRadius.zero,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(compact ? 24 : 56),
          child: compact
              ? Row(children: [
                  const BrandLogo(size: 64),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Mess Ledger', style: text.headlineSmall?.copyWith(color: onHero)),
                      const SizedBox(height: 4),
                      Text('Mehran UET, Jamshoro', style: text.bodyMedium?.copyWith(color: onHero.withValues(alpha: 0.75))),
                    ]),
                  ),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const BrandLogo(size: 76),
                  const SizedBox(height: 32),
                  Text('Hostel Mess Ledger', style: text.displaySmall?.copyWith(color: onHero)),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Text(
                      'A transparent credit ledger for everyone who eats at the mess.',
                      style: text.titleMedium?.copyWith(color: onHero.withValues(alpha: 0.82), fontWeight: FontWeight.w500, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 36),
                  const _Feature(icon: Icons.restaurant, label: 'Log meals in seconds'),
                  const SizedBox(height: 14),
                  const _Feature(icon: Icons.fact_check_outlined, label: 'Managers approve every entry'),
                  const SizedBox(height: 14),
                  const _Feature(icon: Icons.account_balance_wallet_outlined, label: 'Always know what you owe'),
                ]),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final onHero = context.tokens.onHero;
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: onHero.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: onHero),
      ),
      const SizedBox(width: 14),
      Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: onHero.withValues(alpha: 0.92))),
    ]);
  }
}
