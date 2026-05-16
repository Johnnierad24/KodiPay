class AppConfig {
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  static String get apiBaseUrl {
    return _configuredApiBaseUrl.endsWith('/')
        ? _configuredApiBaseUrl.substring(0, _configuredApiBaseUrl.length - 1)
        : _configuredApiBaseUrl;
  }
}
