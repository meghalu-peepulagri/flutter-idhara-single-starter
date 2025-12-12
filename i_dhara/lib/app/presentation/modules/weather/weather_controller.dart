import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class WeatherController extends GetxController {
  RxString locationName = "".obs;
  RxInt temperature = 0.obs;
  RxString weatherIcon = "".obs;
  RxString weatherIcon2 = "".obs;
  RxList hourForecast = [].obs;
  RxBool isLoading = true.obs;

  final dio = Dio();

  @override
  void onInit() {
    super.onInit();
    callWeatherAPI();
  }

  Future<void> callWeatherAPI() async {
    try {
      isLoading.value = true;

      Position pos = await _determinePosition();

      final response = await dio.get(
        "https://api.weatherapi.com/v1/forecast.json",
        queryParameters: {
          "key": "28ac09e8dcd4486889c83425251311",
          "q": "${pos.latitude},${pos.longitude}",
          "days": "1",
          "aqi": "no",
        },
      );

      final data = response.data;

      // ✔️ location
      locationName.value = data["location"]["name"];

      // ✔️ current weather
      final current = data["current"];
      temperature.value = current["temp_c"].toInt();
      weatherIcon2.value = current["condition"]["icon"];

      // ✔️ hourly forecast (first day)
      hourForecast.value = data["forecast"]["forecastday"][0]["hour"];
    } catch (e) {
      print("Weather error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// REQUEST LOCATION PERMISSION
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw "Location service disabled";

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw "Location permission denied";
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}
