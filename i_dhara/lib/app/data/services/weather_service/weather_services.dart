import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:i_dhara/app/core/constants/app_constant.dart';

class WeatherService {
  static String get _baseUrl => AppConstants.weather_url;
  static String get _apiKey => AppConstants.weather_key;

  Future<LocationPermissionStatus> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }

    return LocationPermissionStatus.granted;
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  // Fetch weather data with hourly forecast
  Future<WeatherData?> getWeatherData() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) {
        return null;
      }

      final url = Uri.parse(
        '$_baseUrl?key=$_apiKey&q=${position.latitude},${position.longitude}&days=1&aqi=no&alerts=no',
      );

      // Add timeout to the HTTP request
      final response = await http.get(url).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  bothDisabled,
}

class WeatherData {
  final String location;
  final CurrentWeather current;
  final List<HourlyForecast> hourlyForecast;

  WeatherData({
    required this.location,
    required this.current,
    required this.hourlyForecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final forecastDay = json['forecast']['forecastday'][0];
    final allHours = (forecastDay['hour'] as List)
        .map((hour) => HourlyForecast.fromJson(hour))
        .toList();

    return WeatherData(
      location: json['location']['name'] ?? '',
      current: CurrentWeather.fromJson(json['current']),
      hourlyForecast: allHours,
    );
  }
}

class CurrentWeather {
  final double tempC;
  final String condition;
  final String icon;

  CurrentWeather({
    required this.tempC,
    required this.condition,
    required this.icon,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      tempC: json['temp_c'].toDouble(),
      condition: json['condition']['text'] ?? '',
      icon: json['condition']['icon'] ?? '',
    );
  }
}

class HourlyForecast {
  final DateTime time;
  final double tempC;
  final String condition;
  final String icon;

  HourlyForecast({
    required this.time,
    required this.tempC,
    required this.condition,
    required this.icon,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: DateTime.parse(json['time']),
      tempC: json['temp_c'].toDouble(),
      condition: json['condition']['text'] ?? '',
      icon: json['condition']['icon'] ?? '',
    );
  }
}
