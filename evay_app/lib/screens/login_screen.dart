import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;
  String? _error;
  bool _obscure = true;

  static const _webClientId =
      '214523979621-tjf4ndmgr3p0gjlv1v3sumn90p2lssat.apps.googleusercontent.com';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? context.l10n.t('loginFailed'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });

    try {
      if (kIsWeb) {
        final provider =
            GoogleAuthProvider()
              ..addScope('email')
              ..addScope('profile');
        await FirebaseAuth.instance.signInWithPopup(provider);
        return;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            defaultTargetPlatform == TargetPlatform.iOS
                ? DefaultFirebaseOptions.ios.iosClientId
                : null,
        serverClientId: _webClientId,
        scopes: const ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? context.l10n.t('googleSignInFailed'));
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _error = _googlePlatformErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.l10n.t('googleSignInFailed'));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  String _googlePlatformErrorMessage(PlatformException e) {
    final l10n = context.l10n;
    final details = '${e.message ?? ''} ${e.details ?? ''}';
    if (details.contains('ApiException: 10')) {
      return l10n.t('googleConfigError');
    }
    if (e.code == GoogleSignIn.kSignInCanceledError) {
      return l10n.t('googleSignInCancelled');
    }
    if (e.code == GoogleSignIn.kNetworkError) {
      return l10n.t('googleNetworkError');
    }
    return e.message ?? l10n.t('googleSignInFailed');
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _animController.dispose();
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('welcomeBack'),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.t('loginToContinue'),
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _email,
                                decoration: InputDecoration(
                                  labelText: l10n.t('email'),
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _pass,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: l10n.t('password'),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscure = !_obscure);
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_error != null)
                                Text(
                                  _error!,
                                  style: TextStyle(color: palette.danger),
                                ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                      _loading || _googleLoading
                                          ? null
                                          : _login,
                                  child:
                                      _loading
                                          ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: cs.onPrimary,
                                            ),
                                          )
                                          : Text(l10n.t('login')),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(l10n.t('or')),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _loading || _googleLoading
                                          ? null
                                          : _googleLogin,
                                  icon:
                                      _googleLoading
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Icon(
                                            Icons.g_mobiledata,
                                            size: 28,
                                          ),
                                  label: Text(
                                    _googleLoading
                                        ? l10n.t('connecting')
                                        : l10n.t('continueWithGoogle'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              l10n.t('dontHaveAccount'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
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
