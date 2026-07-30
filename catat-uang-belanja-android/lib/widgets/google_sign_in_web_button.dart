/// Conditional export so app code (and non-web builds) never directly
/// import google_sign_in_web — matches the pattern in the google_sign_in
/// package's own example (example/lib/src/web_wrapper.dart).
library;

export 'google_sign_in_web_button_stub.dart'
    if (dart.library.js_util) 'google_sign_in_web_button_web.dart';
