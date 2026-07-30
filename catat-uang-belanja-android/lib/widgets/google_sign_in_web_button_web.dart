import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Renders Google's own Identity Services button. On web, `google_sign_in`
/// disallows triggering sign-in from a custom button (`authenticate()`
/// throws `UnimplementedError`) — this is the only supported entry point.
Widget renderGoogleSignInWebButton() => web.renderButton();
