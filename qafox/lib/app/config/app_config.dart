import 'environment_config.dart';

class AppConfig {
  final Environment environment;
  final String appName;
  final bool useCloudStorage;

  const AppConfig({
    required this.environment,
    required this.appName,
    this.useCloudStorage = false,
  });

  static const prod = AppConfig(
    environment: Environment.prod,
    appName: 'QA Fox',
    useCloudStorage: true,
  );
}
