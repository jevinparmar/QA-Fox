enum Environment { dev, staging, prod }

class EnvironmentConfig {
  static const Environment environment = Environment.prod;
  static const bool enableLogging = true;
  static const String appName = 'QA Fox';
}
