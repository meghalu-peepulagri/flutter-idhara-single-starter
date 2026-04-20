import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/data/services/weather_service/weather_services.dart';
import 'package:intl/intl.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> with WidgetsBindingObserver {
  final WeatherService _weatherService = WeatherService();
  final ScrollController _scrollController = ScrollController();

  WeatherData? _weatherData;
  LocationPermissionStatus? _permissionStatus;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWeather();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  /// Refresh when returning from settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check if permission wasn't granted or weather data is missing
      // This handles returning from OS permission dialog or app settings
      if (_weatherData == null ||
          _permissionStatus != LocationPermissionStatus.granted) {
        _initializeWeather();
      }
    }
  }

  /// CHECK LOCATION + FETCH WEATHER
  Future<void> _initializeWeather() async {
    setState(() => _isLoading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled && permission == LocationPermission.denied) {
      _permissionStatus = LocationPermissionStatus.bothDisabled;
    } else if (!serviceEnabled) {
      _permissionStatus = LocationPermissionStatus.serviceDisabled;
    } else if (permission == LocationPermission.denied) {
      _permissionStatus = LocationPermissionStatus.denied;
    } else if (permission == LocationPermission.deniedForever) {
      _permissionStatus = LocationPermissionStatus.deniedForever;
    } else {
      _permissionStatus = LocationPermissionStatus.granted;

      final data = await _weatherService.getWeatherData();
      _weatherData = data;
    }

    setState(() => _isLoading = false);
  }

  /// ENABLE GPS
  Future<void> _enableGPS() async {
    await Geolocator.openLocationSettings();
  }

  /// REQUEST LOCATION PERMISSION
  Future<void> _requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      _initializeWeather();
    }
  }

  /// FORMAT TIME
  String _formatTime(DateTime time) {
    final now = DateTime.now();

    if (time.hour == now.hour && time.day == now.day) {
      return "Now";
    }

    return DateFormat('h a').format(time);
  }

  bool _isCurrentHour(DateTime time) {
    final now = DateTime.now();
    return time.hour == now.hour && time.day == now.day;
  }

  HourlyForecast? _currentForecast() {
    if (_weatherData == null) return null;

    final now = DateTime.now();

    for (var item in _weatherData!.hourlyForecast) {
      if (item.time.hour == now.hour) {
        return item;
      }
    }

    return _weatherData!.hourlyForecast.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A4D8C),
            Color(0xFF2D87C8),
          ],
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _permissionStatus != LocationPermissionStatus.granted
              ? _buildPermissionUI()
              : _weatherData == null
                  ? _buildRetryUI()
                  : _buildWeatherUI(),
    );
  }

  /// PERMISSION UI
  Widget _buildPermissionUI() {
    bool gpsOff =
        _permissionStatus == LocationPermissionStatus.serviceDisabled ||
            _permissionStatus == LocationPermissionStatus.bothDisabled;

    bool permissionDenied =
        _permissionStatus == LocationPermissionStatus.denied ||
            _permissionStatus == LocationPermissionStatus.deniedForever ||
            _permissionStatus == LocationPermissionStatus.bothDisabled;

    String title = "Location Permission Required";
    String subtitle =
        "Allow this app to access your location to show local weather.";

    if (gpsOff && permissionDenied) {
      title = "Location Access Needed";
      subtitle =
          "Turn on Device Location (GPS) and allow this app to access your location.";
    } else if (gpsOff) {
      title = "Device Location (GPS) is OFF";
      subtitle =
          "Please enable GPS on your phone to see weather for your location.";
    } else if (_permissionStatus == LocationPermissionStatus.deniedForever) {
      subtitle =
          "Location permission is permanently denied. Enable it from App Settings.";
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.location_off,
            size: 34,
            color: Colors.white70,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (gpsOff)
                      _actionButton(
                        "Enable GPS",
                        Icons.settings,
                        _enableGPS,
                      ),
                    if (permissionDenied)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _actionButton(
                          _permissionStatus ==
                                  LocationPermissionStatus.deniedForever
                              ? "Open Settings"
                              : "Allow Access",
                          Icons.lock_open,
                          _requestPermission,
                        ),
                      )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }

  /// RETRY UI (permission granted but data failed to load)
  Widget _buildRetryUI() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 34, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather data unavailable',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Failed to fetch weather. Check your connection.',
                  style: GoogleFonts.dmSans(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                _actionButton('Retry', Icons.refresh, _initializeWeather),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// WEATHER UI
  Widget _buildWeatherUI() {
    final current = _currentForecast();

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Today's Forecast • ${_weatherData!.location}",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              if (current != null)
                Row(
                  children: [
                    CachedNetworkImage(
                      imageUrl: "https:${current.icon}",
                      width: 26,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${current.tempC.round()}°C",
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  ],
                )
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _weatherData!.hourlyForecast.length,
              itemBuilder: (context, index) {
                final item = _weatherData!.hourlyForecast[index];
                bool isNow = _isCurrentHour(item.time);

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isNow ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(item.time),
                        style: GoogleFonts.dmSans(
                          color: isNow ? Colors.blue : Colors.white,
                          fontSize: 12,
                          fontWeight:
                              isNow ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CachedNetworkImage(
                        imageUrl: "https:${item.icon}",
                        width: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${item.tempC.round()}°C",
                        style: GoogleFonts.dmSans(
                          color: isNow ? Colors.blue : Colors.white,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
