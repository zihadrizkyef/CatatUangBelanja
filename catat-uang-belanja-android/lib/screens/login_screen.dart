import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../repositories/finance_repository.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'login_view.dart';

/// Reached from Pengaturan's "Masuk dengan Google" action — doc 4.10/6.1:
/// login is Google Sign-In only, no phone/OTP or password, and strictly
/// optional (doc 8's offline-first requirement means the rest of the app
/// must work with zero account; this screen is never a startup gate). On
/// success, refreshes [FinanceRepository.refreshLoginState] and pops back
/// to Pengaturan. Reads [FinanceRepository] and drives [AuthService]; hands
/// the rest to [LoginView].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();
  bool _isSigningIn = false;
  String? _errorText;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authEventsSubscription;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Web can't trigger sign-in from our own button (authenticate()
      // throws there) — LoginView renders Google's own button instead,
      // whose result arrives through this stream rather than a return
      // value. Pre-initializing here (rather than waiting for a tap) lets
      // that button render as soon as the SDK is ready.
      unawaited(_authService.ensureInitialized());
      _authEventsSubscription = _authService.authenticationEvents.listen(_onWebAuthEvent);
    }
  }

  @override
  void dispose() {
    _authEventsSubscription?.cancel();
    super.dispose();
  }

  void _onWebAuthEvent(GoogleSignInAuthenticationEvent event) {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      unawaited(_handleSignIn(() => _authService.completeSignIn(event.user)));
    }
  }

  Future<void> _signIn() => _handleSignIn(_authService.signIn);

  /// Shared tail for both entry points: [_signIn] (mobile, driven by our
  /// own button tap) and [_onWebAuthEvent] (web, driven by Google's button
  /// reporting a result asynchronously).
  Future<void> _handleSignIn(Future<AuthUser> Function() run) async {
    setState(() {
      _isSigningIn = true;
      _errorText = null;
    });

    try {
      await run();
      if (!mounted) return;
      await context.read<FinanceRepository>().refreshLoginState();
      if (!mounted) return;
      // First sync right after login gives an immediate "your data is safe
      // now" feel; SyncService's connectivity listener covers subsequent
      // syncs automatically from here on (doc 4.10).
      unawaited(context.read<SyncService>().syncNow());
      if (Navigator.canPop(context)) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _errorText = e.message);
    } on GoogleSignInException catch (e) {
      // `canceled` is just the user backing out of the account picker — not
      // an error worth a scary message, quietly reset the button. Anything
      // else (e.g. `clientConfigurationError` when the OAuth client isn't
      // set up yet) previously failed the exact same silent way, which
      // looked like the button did nothing at all — surface it instead.
      if (e.code != GoogleSignInExceptionCode.canceled) {
        setState(() => _errorText = 'Masuk dengan Google belum bisa dipakai saat ini, Bun. Coba lagi nanti ya.');
      }
    } catch (e) {
      // Anything outside the two expected exception types (e.g. a raw
      // PlatformException from the native side when Play Services /
      // the OAuth client isn't set up) — surfaced verbatim for now since
      // Google Sign-In setup is still in progress and needs the real
      // underlying error to diagnose, not a friendly message that hides it.
      setState(() => _errorText = 'Gagal masuk: $e');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginView(isSigningIn: _isSigningIn, errorText: _errorText, onTapGoogleSignIn: _signIn);
  }
}
