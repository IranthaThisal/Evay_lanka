import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? context.l10n.t('registrationFailed'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.evayPalette;
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: palette.heroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          l10n.t('createAccount'),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.t('registerIntro'),
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _email,
                          decoration: InputDecoration(labelText: l10n.t('email')),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pass,
                          decoration: InputDecoration(
                            labelText: l10n.t('password'),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        if (_error != null)
                          Text(_error!, style: TextStyle(color: palette.danger)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _register,
                            child:
                                _loading
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.onPrimary,
                                      ),
                                    )
                                    : Text(l10n.t('register')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
