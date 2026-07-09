class AppEnv {
  const AppEnv._();

  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;

    switch (environment) {
      case 'prod':
        return 'https://api.urbansync.example';
      case 'staging':
        return 'https://staging.urbansync.example';
      default:
        return 'http://10.0.2.2:8080';
    }
  }
}
