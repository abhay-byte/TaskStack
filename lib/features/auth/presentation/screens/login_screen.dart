import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskstack/features/auth/presentation/providers/auth_provider.dart';
import 'package:taskstack/features/auth/presentation/widgets/auth_screen_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _showWakeHint = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Show wake hint after 3 s — Render 502 retry loop takes up to 30 s
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && ref.read(authNotifierProvider) is AuthLoading) {
        setState(() => _showWakeHint = true);
      }
    });
    await ref
        .read(authNotifierProvider.notifier)
        .login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (mounted) setState(() => _showWakeHint = false);
    // GoRouter redirect handles navigation on AuthAuthenticated
  }

  Future<void> _submitGoogle() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authNotifierProvider);
    final isLoading = state is AuthLoading;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AuthUnauthenticated && next.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return AuthScreenScaffold(
      title: 'Welcome back',
      subtitle:
          'Sign in with email or Google to sync tasks, groups, and your profile across devices.',
      footer: TextButton.icon(
        onPressed:
            isLoading
                ? null
                : () {
                  ref.read(authNotifierProvider.notifier).continueAsGuest();
                  context.go('/');
                },
        icon: const Icon(Icons.person_outline),
        label: const Text('Continue as guest for offline mode'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GoogleAuthButton(
              label: 'Continue with Google',
              isLoading: isLoading,
              onPressed: _submitGoogle,
            ),
            const SizedBox(height: 12),
            Text(
              'If this Google account already exists, we’ll sign you in. If not, TaskStack will create it for you.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            const AuthSectionDivider(label: 'or use email'),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Sign In'),
            ),
            if (isLoading && _showWakeHint) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_sync_outlined,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Waking up server... please wait',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: isLoading ? null : () => context.go('/signup'),
              child: const Text("Don't have an account? Create one"),
            ),
          ],
        ),
      ),
    );
  }
}
