class AppConfig {
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  /// OAuth **web** client ID from Google Cloud Console. Used as the
  /// `serverClientId` for Google Sign-In so the backend can verify the
  /// returned ID token. Provide via `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
  /// When empty, the Google sign-in button reports that it isn't configured
  /// yet instead of crashing.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    return _configuredApiBaseUrl.endsWith('/')
        ? _configuredApiBaseUrl.substring(0, _configuredApiBaseUrl.length - 1)
        : _configuredApiBaseUrl;
  }
}
