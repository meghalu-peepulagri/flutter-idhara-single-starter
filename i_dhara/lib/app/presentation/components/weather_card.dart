import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
import 'package:i_dhara/app/data/services/weather_service/weather_services.dart';

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
  final bool _hasRequestedPermission = false;
  Timer? _hourCheckTimer;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  bool _isInitializing = false;

  static DateTime? _lastFetchTime;
  static WeatherData? _cachedWeatherData;
  static LocationPermissionStatus? _cachedPermissionStatus;
  static const Duration _cacheDuration = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWeatherCard();
    _startHourCheckTimer();
    if (!kIsWeb) {
      _listenToLocationServiceChanges();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hourCheckTimer?.cancel();
    _serviceStatusSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void _startHourCheckTimer() {
    _hourCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _listenToLocationServiceChanges() {
    if (kIsWeb) return;

    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) {
        if (status == ServiceStatus.enabled) {
          _forceRefresh();
        } else {
          setState(() {
            _permissionStatus = LocationPermissionStatus.serviceDisabled;
            _cachedPermissionStatus = LocationPermissionStatus.serviceDisabled;
            _weatherData = null;
            _cachedWeatherData = null;
            _lastFetchTime = null;
            _isInitializing = false;
          });
        }
      },
    );
  }

  bool _isCacheValid() {
    if (_lastFetchTime == null || _cachedWeatherData == null) {
      return false;
    }
    final now = DateTime.now();
    final difference = now.difference(_lastFetchTime!);
    return difference < _cacheDuration;
  }

  void _checkAndRefreshIfNeeded() {
    if (_isCacheValid()) {
      setState(() {
        _weatherData = _cachedWeatherData;
        _permissionStatus = _cachedPermissionStatus;
        _isInitializing = false;
      });
    } else {
      _forceRefresh();
    }
  }

  Future<void> _forceRefresh() async {
    setState(() => _isInitializing = true);
    _lastFetchTime = null;
    _cachedWeatherData = null;
    _cachedPermissionStatus = null;
    await _initializeWeatherCard();
  }

  Future<void> _initializeWeatherCard() async {
    if (_isCacheValid() && !_isInitializing) {
      setState(() {
        _weatherData = _cachedWeatherData;
        _permissionStatus = _cachedPermissionStatus;
      });
      _scrollToCurrentHour();
      return;
    }

    if (!_isInitializing) setState(() => _isInitializing = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _permissionStatus = LocationPermissionStatus.serviceDisabled;
        _cachedPermissionStatus = LocationPermissionStatus.serviceDisabled;
        _isInitializing = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionStatus = permission == LocationPermission.deniedForever
            ? LocationPermissionStatus.deniedForever
            : LocationPermissionStatus.denied;
        _cachedPermissionStatus = _permissionStatus;
        _isInitializing = false;
      });
      return;
    }

    setState(() {
      _permissionStatus = LocationPermissionStatus.granted;
      _cachedPermissionStatus = LocationPermissionStatus.granted;
    });

    final weatherData = await _weatherService.getWeatherData();
    if (weatherData != null) {
      _lastFetchTime = DateTime.now();
      _cachedWeatherData = weatherData;
    }

    setState(() {
      _weatherData = weatherData;
      _isInitializing = false;
    });

    _scrollToCurrentHour();
  }

  void _scrollToCurrentHour() {
    if (_weatherData == null || !_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollToCurrentHourActual();
        }
      });
      return;
    }
    _scrollToCurrentHourActual();
  }

  void _scrollToCurrentHourActual() {
    if (!mounted || _weatherData == null || !_scrollController.hasClients)
      return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;

    final now = DateTime.now();
    int currentHourIndex = -1;

    for (int i = 0; i < _weatherData!.hourlyForecast.length; i++) {
      if (_isCurrentHour(_weatherData!.hourlyForecast[i].time)) {
        currentHourIndex = i;
        break;
      }
    }

    if (currentHourIndex != -1) {
      const itemWidth = 50.0;
      final scrollPosition = currentHourIndex * itemWidth;
      final clampedPosition = scrollPosition.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );

      _scrollController.animateTo(
        clampedPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleEnableLocation() async {
    if (_permissionStatus == LocationPermissionStatus.serviceDisabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // Always check current actual permission state first
    final currentPermission = await Geolocator.checkPermission();

    if (currentPermission == LocationPermission.deniedForever) {
      // Must go to app settings - can't request programmatically
      await Geolocator.openAppSettings();
      return;
    }

    if (currentPermission == LocationPermission.denied) {
      // Try requesting — Android may block after 2nd denial
      final result = await Geolocator.requestPermission();

      if (result == LocationPermission.whileInUse ||
          result == LocationPermission.always) {
        await _forceRefresh();
      } else if (result == LocationPermission.deniedForever) {
        setState(() {
          _permissionStatus = LocationPermissionStatus.deniedForever;
          _cachedPermissionStatus = LocationPermissionStatus.deniedForever;
        });
        // Immediately open app settings since it's now forever denied
        await Geolocator.openAppSettings();
      } else {
        // Still denied — next time force app settings
        setState(() {
          _permissionStatus = LocationPermissionStatus.deniedForever;
          _cachedPermissionStatus = LocationPermissionStatus.deniedForever;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckPermissionAfterSettings();
    }
  }

  Future<void> _recheckPermissionAfterSettings() async {
    // Re-check location service first
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _permissionStatus = LocationPermissionStatus.serviceDisabled;
        _cachedPermissionStatus = LocationPermissionStatus.serviceDisabled;
        _isInitializing = false;
      });
      return;
    }

    // Re-check app permission
    final permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      // Granted — fetch weather
      await _forceRefresh();
    } else {
      final newStatus = permission == LocationPermission.deniedForever
          ? LocationPermissionStatus.deniedForever
          : LocationPermissionStatus.denied;

      setState(() {
        _permissionStatus = newStatus;
        _cachedPermissionStatus = newStatus;
        _isInitializing = false;
      });
    }
  }

  String _getButtonText() {
    switch (_permissionStatus) {
      case LocationPermissionStatus.deniedForever:
        return 'Open Settings';
      case LocationPermissionStatus.serviceDisabled:
        return 'Enable Location';
      default:
        return 'Enable Location';
    }
  }

  String _getTimeFormat(DateTime time) {
    final now = DateTime.now();
    if (time.hour == now.hour && time.day == now.day) {
      return 'Now';
    }
    return DateFormat('h a').format(time);
  }

  bool _isCurrentHour(DateTime time) {
    final now = DateTime.now();
    return time.hour == now.hour && time.day == now.day;
  }

  bool _isPastHour(DateTime time) {
    final now = DateTime.now();
    return time.isBefore(DateTime(now.year, now.month, now.day, now.hour));
  }

  HourlyForecast? _getCurrentHourForecast() {
    if (_weatherData == null) return null;

    final now = DateTime.now();
    for (var forecast in _weatherData!.hourlyForecast) {
      if (forecast.time.hour == now.hour && forecast.time.day == now.day) {
        return forecast;
      }
    }
    return _weatherData!.hourlyForecast.isNotEmpty
        ? _weatherData!.hourlyForecast.first
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140.0,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF004E7E),
            Color(0xFF3686AF),
          ],
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: _isInitializing
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : (_permissionStatus != LocationPermissionStatus.granted ||
                  _weatherData == null)
              ? _buildPermissionUI()
              : _buildWeatherContent(),
    );
  }

  Widget _buildPermissionUI() {
    final bool isServiceDisabled =
        _permissionStatus == LocationPermissionStatus.serviceDisabled;

    if (isServiceDisabled) {
      return _buildLocationBanner(
        icon: Icons.location_disabled,
        heading: 'System Location (GPS) is Off',
        description:
            "To function, iDhara requires your device's location services (GPS) to be turned ON.",
        buttonText: 'Go to System Settings →',
        onTap: _handleEnableLocation, // ← single handler
      );
    }

    return _buildLocationBanner(
      icon: Icons.phone_android,
      heading: 'App Location Access is Denied',
      description:
          "The iDhara app does not have permission to access your location. Please grant 'While using the app' permission.",
      buttonText: _permissionStatus == LocationPermissionStatus.deniedForever
          ? 'Go to App Settings →'
          : 'Grant Permission →',
      onTap: _handleEnableLocation, // ← single handler
    );
  }

  Widget _buildLocationBanner({
    required IconData icon,
    required String heading,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon with X overlay
          Stack(
            children: [
              const Icon(Icons.location_on, size: 44, color: Colors.white70),
              Positioned(
                right: 0,
                bottom: 0,
                child: Icon(Icons.cancel, size: 18, color: Colors.red[300]),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Text section
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Button
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white38),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    final currentForecast = _getCurrentHourForecast();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Today\'s Forecast - ${_weatherData!.location}',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w500,
                          ),
                          color: const Color(0xFFFFFFFF),
                          fontSize: 12.0,
                          letterSpacing: 0.0,
                        ),
                  ),
                ),
                if (currentForecast != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CachedNetworkImage(
                        imageUrl: 'https:${currentForecast.icon}',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error, size: 24),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${currentForecast.tempC.round()}°C',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                              ),
                              color: const Color(0xFFFFFFFF),
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: _weatherData!.hourlyForecast.length,
                separatorBuilder: (context, index) => const Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(
                      height: 50.0,
                      child: VerticalDivider(
                        thickness: 1.0,
                        color: Color(0xFFFFFF99),
                      ),
                    ),
                  ],
                ),
                itemBuilder: (context, index) {
                  final forecast = _weatherData!.hourlyForecast[index];
                  final isNow = _isCurrentHour(forecast.time);
                  final isPast = _isPastHour(forecast.time);

                  return Container(
                    decoration: BoxDecoration(
                      color:
                          isNow ? const Color(0xFFE3F2FD) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Opacity(
                      opacity: isPast ? 0.5 : 1.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getTimeFormat(forecast.time),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.dmSans(
                                    fontWeight: isNow
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  color: isNow
                                      ? const Color(0xFF1976D2)
                                      : const Color(0xFFFFFFFF),
                                  fontSize: 12.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                          CachedNetworkImage(
                            imageUrl: 'https:${forecast.icon}',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, size: 32),
                          ),
                          Text(
                            '${forecast.tempC.round()}°C',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.dmSans(
                                    fontWeight: isNow
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  color: isNow
                                      ? const Color(0xFF1976D2)
                                      : const Color(0xFFFFFFFF),
                                  fontSize: 12.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ].divide(const SizedBox(height: 2.0)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ].divide(const SizedBox(height: 16.0)),
      ),
    );
  }
}
