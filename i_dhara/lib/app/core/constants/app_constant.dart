import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get dev_url => dotenv.env['dev_url'] ?? '';
  static String get live_url => dotenv.env['live_url'] ?? '';
  static String get local_url => dotenv.env['local_url'] ?? '';
  static String get weather_url => dotenv.env['weather_url'] ?? '';
  static String get weather_key => dotenv.env['weather_key'] ?? '';
}
