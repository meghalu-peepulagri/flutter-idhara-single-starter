import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment { dev, staging, live }

abstract class AppEnvironment {
  static late String baseApiUrl;
  static late String title;
  static late Environment _environment;

  static late String mqttBroker;
  static late int mqttPort;
  static late String mqttUsername;
  static late String mqttPassword;

  static Environment get environment => _environment;

  static void setup() {
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (envString) {
      case 'staging':
        setupEnv(Environment.staging);
        break;
      case 'live':
        setupEnv(Environment.live);
        break;
      case 'dev':
      default:
        setupEnv(Environment.dev);
    }
  }

  static void setupEnv(Environment data) {
    _environment = data;
    switch (data) {
      case Environment.dev:
        baseApiUrl = dotenv.env["dev_url"]!;
        title = "dev";
        mqttBroker = dotenv.env["mqttBroker_dev"]!;
        mqttPort = int.parse(dotenv.env["PORT"]!);
        mqttUsername = dotenv.env["mqttUsername_dev"]!;
        mqttPassword = dotenv.env["mqttPassword_dev"]!;
        break;

      case Environment.staging:
        baseApiUrl = dotenv.env["staging_url"]!;
        title = "staging";
        mqttBroker = dotenv.env["mqttBroker_staging"]!;
        mqttPort = int.parse(dotenv.env["PORT"]!);
        mqttUsername = dotenv.env["mqttUsername_staging"]!;
        mqttPassword = dotenv.env["mqttPassword_staging"]!;
        break;

      case Environment.live:
        baseApiUrl = dotenv.env["live_url"]!;
        title = "live";
        mqttBroker = dotenv.env["mqttBroker_live"]!;
        mqttPort = int.parse(dotenv.env["PORT"]!);
        mqttUsername = dotenv.env["mqttUsername_live"]!;
        mqttPassword = dotenv.env["mqttPassword_live"]!;
        break;
    }
  }
}
