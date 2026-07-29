/// App-lock mode (doc 4.11): no lock, a 6-digit PIN, or biometric
/// (fingerprint/Face ID) with PIN fallback.
enum AppLockType {
  none,
  pin,
  biometric;

  static AppLockType fromName(String name) => AppLockType.values.byName(name);
}
