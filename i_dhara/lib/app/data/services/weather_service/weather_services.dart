import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl = 'https://api.weatherapi.com/v1/forecast.json';
  static const String _apiKey = '28ac09e8dcd4486889c83425251311';

  // Check and request location permissions
  Future<LocationPermissionStatus> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
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

  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Open app settings for permission
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting position: $e');
      return null;
    }
  }

  // Fetch weather data with hourly forecast
  Future<WeatherData?> getWeatherData() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) {
        print('Position is null');
        return null;
      }

      print('Got position: ${position.latitude}, ${position.longitude}');

      final url = Uri.parse(
        '$_baseUrl?key=$_apiKey&q=${position.latitude},${position.longitude}&days=1&aqi=no&alerts=no',
      );

      print('Fetching weather from: $url');

      // Add timeout to the HTTP request
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Weather API request timeout');
          throw Exception('Request timeout');
        },
      );

      print('Weather API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response body length: ${response.body.length}');
        final data = json.decode(response.body);
        print('Weather data parsed successfully');
        return WeatherData.fromJson(data);
      } else {
        print('Weather API error: ${response.statusCode} - ${response.body}');
      }

      return null;
    } catch (e, stackTrace) {
      print('Error fetching weather data: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
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
    // Get current hour
    final now = DateTime.now();
    final currentHour = now.hour;

    // Extract all hours from today's forecast
    final forecastDay = json['forecast']['forecastday'][0];
    final allHours = (forecastDay['hour'] as List)
        .map((hour) => HourlyForecast.fromJson(hour))
        .toList();

    // Filter to get next 24 hours starting from current hour
    final List<HourlyForecast> next24Hours = [];

    for (var hour in allHours) {
      if (hour.time.hour >= currentHour || hour.time.day > now.day) {
        next24Hours.add(hour);
      }
    }

    // If we don't have 24 hours, it means we need to handle it differently
    // For now, we'll just take what we have

    return WeatherData(
      location: json['location']['name'] ?? '',
      current: CurrentWeather.fromJson(json['current']),
      hourlyForecast: next24Hours,
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
