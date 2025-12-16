import 'dart:async';

import 'package:get/get.dart';
import 'package:i_dhara/app/data/services/weather_service/weather_services.dart';

class WeatherController extends GetxController {
  final WeatherService _weatherService = WeatherService();

  final Rx<WeatherData?> weatherData = Rx<WeatherData?>(null);
  final RxBool isLoading = false.obs;
  final Rx<LocationPermissionStatus?> permissionStatus =
      Rx<LocationPermissionStatus?>(null);

  Timer? _hourTimer;

  @override
  void onInit() {
    super.onInit();

    // Load ONLY ONCE
    if (weatherData.value == null) {
      loadWeather();
    }

    _startHourTimer();
  }

  void _startHourTimer() {
    _hourTimer?.cancel();
    _hourTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      update(); // rebuild UI for "Now" hour change
    });
  }

  Future<void> loadWeather() async {
    isLoading.value = true;

    final status = await _weatherService.handleLocationPermission();
    permissionStatus.value = status;

    if (status == LocationPermissionStatus.granted) {
      weatherData.value = await _weatherService.getWeatherData();
    }

    isLoading.value = false;
  }

  @override
  void onClose() {
    _hourTimer?.cancel();
    super.onClose();
  }
}
