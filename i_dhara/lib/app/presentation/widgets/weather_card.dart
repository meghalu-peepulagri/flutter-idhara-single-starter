import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
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
  WeatherData? _weatherData;
  bool _isLoading = true;
  LocationPermissionStatus? _permissionStatus;
  bool _hasRequestedPermission = false;
  Timer? _hourCheckTimer;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestLocationPermissionDirectly();
    _startHourCheckTimer();
    _listenToLocationServiceChanges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hourCheckTimer?.cancel();
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from settings, reload weather data
    if (state == AppLifecycleState.resumed) {
      _loadWeatherData();
    }
  }

  void _startHourCheckTimer() {
    // Check every minute if the hour has changed
    _hourCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild and update the "Now" indicator
        });
      }
    });
  }

  void _listenToLocationServiceChanges() {
    // Listen to location service status changes
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) {
        if (status == ServiceStatus.enabled) {
          // Location service turned on, reload data
          _loadWeatherData();
        } else {
          // Location service turned off
          setState(() {
            _permissionStatus = LocationPermissionStatus.serviceDisabled;
            _weatherData = null;
          });
        }
      },
    );
  }

  Future<void> _requestLocationPermissionDirectly() async {
    setState(() => _isLoading = true);

    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _permissionStatus = LocationPermissionStatus.serviceDisabled;
        _isLoading = false;
      });
      return;
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied && !_hasRequestedPermission) {
      // Request permission directly - this will show the system dialog
      _hasRequestedPermission = true;
      permission = await Geolocator.requestPermission();
    }

    // Handle the permission result
    if (permission == LocationPermission.denied) {
      setState(() {
        _permissionStatus = LocationPermissionStatus.denied;
        _isLoading = false;
      });
    } else if (permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionStatus = LocationPermissionStatus.deniedForever;
        _isLoading = false;
      });
    } else {
      // Permission granted - load weather data
      setState(() {
        _permissionStatus = LocationPermissionStatus.granted;
      });
      await _loadWeatherDataAfterPermission();
    }
  }

  Future<void> _loadWeatherData() async {
    setState(() => _isLoading = true);

    final status = await _weatherService.handleLocationPermission();
    setState(() {
      _permissionStatus = status;
    });

    if (status == LocationPermissionStatus.granted) {
      final weatherData = await _weatherService.getWeatherData();
      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWeatherDataAfterPermission() async {
    final weatherData = await _weatherService.getWeatherData();
    setState(() {
      _weatherData = weatherData;
      _isLoading = false;
    });
  }

  Future<void> _handleEnableLocation() async {
    if (_permissionStatus == LocationPermissionStatus.deniedForever) {
      // Open app settings if permission is permanently denied
      await Geolocator.openAppSettings();
    } else if (_permissionStatus == LocationPermissionStatus.serviceDisabled) {
      // Open location settings if service is disabled
      await Geolocator.openLocationSettings();
    } else {
      // For first time denial, request permission again
      await _requestLocationPermissionDirectly();
    }
  }

  String _getPermissionMessage() {
    switch (_permissionStatus) {
      case LocationPermissionStatus.deniedForever:
        return 'Location permission permanently denied.\nPlease enable it from Settings.';
      case LocationPermissionStatus.denied:
      default:
        return 'Enable location to see weather forecast';
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

    // If it's the current hour, show "Now"
    if (time.hour == now.hour && time.day == now.day) {
      return 'Now';
    }

    // Format as 24-hour time (e.g., "14:00", "15:00" HH:mm)
    return DateFormat('h a').format(time);
  }

  bool _isCurrentHour(DateTime time) {
    final now = DateTime.now();
    return time.hour == now.hour && time.day == now.day;
  }

  HourlyForecast? _getCurrentHourForecast() {
    if (_weatherData == null) return null;

    final now = DateTime.now();
    for (var forecast in _weatherData!.hourlyForecast) {
      if (forecast.time.hour == now.hour && forecast.time.day == now.day) {
        return forecast;
      }
    }

    // If current hour not found, return first forecast
    return _weatherData!.hourlyForecast.isNotEmpty
        ? _weatherData!.hourlyForecast.first
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_permissionStatus != LocationPermissionStatus.granted ||
        _weatherData == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _permissionStatus == LocationPermissionStatus.serviceDisabled
                    ? Icons.location_disabled
                    : Icons.location_off,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Location Permission Required',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                      ),
                      color: const Color(0xFF121212),
                      fontSize: 14.0,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _getPermissionMessage(),
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.dmSans(),
                      color: const Color(0xFF8C8C8C),
                      fontSize: 12.0,
                    ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _handleEnableLocation,
                icon: Icon(
                  _permissionStatus == LocationPermissionStatus.deniedForever
                      ? Icons.settings
                      : Icons.location_on,
                  size: 20,
                ),
                label: Text(_getButtonText()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentForecast = _getCurrentHourForecast();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
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
                            color: const Color(0xFF121212),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error, size: 24),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${currentForecast.tempC.round()}°C',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    color: const Color(0xFF1976D2),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                  ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: 80.0,
              decoration: const BoxDecoration(),
              child: Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                child: ListView.separated(
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
                          color: Color(0x1A000000),
                        ),
                      ),
                    ],
                  ),
                  itemBuilder: (context, index) {
                    final forecast = _weatherData!.hourlyForecast[index];
                    final isNow = _isCurrentHour(forecast.time);

                    return Container(
                      decoration: BoxDecoration(
                        color: isNow
                            ? const Color(0xFFE3F2FD)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                                      : const Color(0xFF8C8C8C),
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
                                      : const Color(0xFF2B2B2B),
                                  fontSize: 12.0,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ].divide(const SizedBox(height: 4.0)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ].divide(const SizedBox(height: 12.0)),
        ),
      ),
    );
  }
}
// import 'dart:async';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
// import 'package:i_dhara/app/data/services/weather_service/weather_services.dart';
// import 'package:i_dhara/app/presentation/modules/weather/weather_controller.dart';

// class WeatherCard extends StatelessWidget {
//   const WeatherCard({super.key});

//   String _getPermissionMessage(LocationPermissionStatus? status) {
//     switch (status) {
//       case LocationPermissionStatus.deniedForever:
//         return 'Location permission permanently denied.\nPlease enable it from Settings.';
//       case LocationPermissionStatus.serviceDisabled:
//         return 'Location service is disabled.\nPlease enable it.';
//       case LocationPermissionStatus.denied:
//       default:
//         return 'Enable location to see weather forecast';
//     }
//   }

//   String _getButtonText(LocationPermissionStatus? status) {
//     switch (status) {
//       case LocationPermissionStatus.deniedForever:
//         return 'Open Settings';
//       case LocationPermissionStatus.serviceDisabled:
//         return 'Enable Location Service';
//       default:
//         return 'Enable Location';
//     }
//   }

//   Future<void> _handleEnableLocation(LocationPermissionStatus? status) async {
//     if (status == LocationPermissionStatus.deniedForever) {
//       await Geolocator.openAppSettings();
//     } else if (status == LocationPermissionStatus.serviceDisabled) {
//       await Geolocator.openLocationSettings();
//     } else {
//       // Re-request permission
//       final controller = Get.find<WeatherController>();
//       await controller.loadWeather();
//     }
//   }

//   String _getTimeFormat(DateTime time) {
//     final now = DateTime.now();

//     // If it's the current hour, show "Now"
//     if (time.hour == now.hour && time.day == now.day) {
//       return 'Now';
//     }

//     // Format as 24-hour time (e.g., "14:00", "15:00")
//     return DateFormat('HH:mm').format(time);
//   }

//   bool _isCurrentHour(DateTime time) {
//     final now = DateTime.now();
//     return time.hour == now.hour && time.day == now.day;
//   }

//   HourlyForecast? _getCurrentHourForecast(WeatherData? weatherData) {
//     if (weatherData == null) return null;

//     final now = DateTime.now();
//     for (var forecast in weatherData.hourlyForecast) {
//       if (forecast.time.hour == now.hour && forecast.time.day == now.day) {
//         return forecast;
//       }
//     }

//     // If current hour not found, return first forecast
//     return weatherData.hourlyForecast.isNotEmpty
//         ? weatherData.hourlyForecast.first
//         : null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Find or create the controller
//     final controller = Get.put(WeatherController(), permanent: true);

//     return Obx(() {
//       // Show loading only on first load
//       if (controller.isLoading.value && controller.weatherData.value == null) {
//         return Container(
//           height: 200,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(10.0),
//           ),
//           child: const Center(
//             child: CircularProgressIndicator(),
//           ),
//         );
//       }

//       // Show permission error
//       if (controller.permissionStatus.value !=
//               LocationPermissionStatus.granted ||
//           controller.weatherData.value == null) {
//         return Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(10.0),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   controller.permissionStatus.value ==
//                           LocationPermissionStatus.serviceDisabled
//                       ? Icons.location_disabled
//                       : Icons.location_off,
//                   size: 48,
//                   color: Colors.grey[400],
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   'Location Permission Required',
//                   style: FlutterFlowTheme.of(context).bodyMedium.override(
//                         font: GoogleFonts.dmSans(
//                           fontWeight: FontWeight.w600,
//                         ),
//                         color: const Color(0xFF121212),
//                         fontSize: 14.0,
//                       ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   _getPermissionMessage(controller.permissionStatus.value),
//                   textAlign: TextAlign.center,
//                   style: FlutterFlowTheme.of(context).bodyMedium.override(
//                         font: GoogleFonts.dmSans(),
//                         color: const Color(0xFF8C8C8C),
//                         fontSize: 12.0,
//                       ),
//                 ),
//                 const SizedBox(height: 12),
//                 ElevatedButton.icon(
//                   onPressed: () =>
//                       _handleEnableLocation(controller.permissionStatus.value),
//                   icon: Icon(
//                     controller.permissionStatus.value ==
//                             LocationPermissionStatus.deniedForever
//                         ? Icons.settings
//                         : Icons.location_on,
//                     size: 20,
//                   ),
//                   label:
//                       Text(_getButtonText(controller.permissionStatus.value)),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF4CAF50),
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }

//       // Show weather data
//       final weatherData = controller.weatherData.value!;
//       final currentForecast = _getCurrentHourForecast(weatherData);

//       return GetBuilder<WeatherController>(
//         builder: (_) {
//           return Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(10.0),
//             ),
//             child: Padding(
//               padding:
//                   const EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 10.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.max,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsetsDirectional.fromSTEB(
//                         12.0, 0.0, 12.0, 0.0),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.max,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Text(
//                             'Today\'s Hourly Forecast - ${weatherData.location}',
//                             style: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .override(
//                                   font: GoogleFonts.dmSans(
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                   color: const Color(0xFF121212),
//                                   fontSize: 12.0,
//                                   letterSpacing: 0.0,
//                                 ),
//                           ),
//                         ),
//                         if (currentForecast != null)
//                           Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               CachedNetworkImage(
//                                 imageUrl: 'https:${currentForecast.icon}',
//                                 width: 24,
//                                 height: 24,
//                                 fit: BoxFit.cover,
//                                 placeholder: (context, url) => const SizedBox(
//                                   width: 24,
//                                   height: 24,
//                                   child: Center(
//                                     child: SizedBox(
//                                       width: 12,
//                                       height: 12,
//                                       child: CircularProgressIndicator(
//                                           strokeWidth: 2),
//                                     ),
//                                   ),
//                                 ),
//                                 errorWidget: (context, url, error) =>
//                                     const Icon(Icons.error, size: 24),
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 '${currentForecast.tempC.round()}°C',
//                                 style: FlutterFlowTheme.of(context)
//                                     .bodyMedium
//                                     .override(
//                                       font: GoogleFonts.dmSans(
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                       color: const Color(0xFF1976D2),
//                                       fontSize: 14.0,
//                                       letterSpacing: 0.0,
//                                     ),
//                               ),
//                             ],
//                           ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     width: double.infinity,
//                     height: 80.0,
//                     decoration: const BoxDecoration(),
//                     child: Padding(
//                       padding: const EdgeInsetsDirectional.fromSTEB(
//                           12.0, 0.0, 12.0, 0.0),
//                       child: ListView.separated(
//                         padding: EdgeInsets.zero,
//                         shrinkWrap: true,
//                         scrollDirection: Axis.horizontal,
//                         itemCount: weatherData.hourlyForecast.length,
//                         separatorBuilder: (context, index) => const Row(
//                           mainAxisSize: MainAxisSize.max,
//                           children: [
//                             SizedBox(
//                               height: 50.0,
//                               child: VerticalDivider(
//                                 thickness: 1.0,
//                                 color: Color(0x1A000000),
//                               ),
//                             ),
//                           ],
//                         ),
//                         itemBuilder: (context, index) {
//                           final forecast = weatherData.hourlyForecast[index];
//                           final isNow = _isCurrentHour(forecast.time);

//                           return Container(
//                             decoration: BoxDecoration(
//                               color: isNow
//                                   ? const Color(0xFFE3F2FD)
//                                   : Colors.transparent,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 8, vertical: 4),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.max,
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   _getTimeFormat(forecast.time),
//                                   style: FlutterFlowTheme.of(context)
//                                       .bodyMedium
//                                       .override(
//                                         font: GoogleFonts.dmSans(
//                                           fontWeight: isNow
//                                               ? FontWeight.w700
//                                               : FontWeight.w500,
//                                         ),
//                                         color: isNow
//                                             ? const Color(0xFF1976D2)
//                                             : const Color(0xFF8C8C8C),
//                                         fontSize: 12.0,
//                                         letterSpacing: 0.0,
//                                       ),
//                                 ),
//                                 CachedNetworkImage(
//                                   imageUrl: 'https:${forecast.icon}',
//                                   width: 32,
//                                   height: 32,
//                                   fit: BoxFit.cover,
//                                   placeholder: (context, url) => const SizedBox(
//                                     width: 32,
//                                     height: 32,
//                                     child: Center(
//                                       child: SizedBox(
//                                         width: 16,
//                                         height: 16,
//                                         child: CircularProgressIndicator(
//                                             strokeWidth: 2),
//                                       ),
//                                     ),
//                                   ),
//                                   errorWidget: (context, url, error) =>
//                                       const Icon(Icons.error, size: 32),
//                                 ),
//                                 Text(
//                                   '${forecast.tempC.round()}°C',
//                                   style: FlutterFlowTheme.of(context)
//                                       .bodyMedium
//                                       .override(
//                                         font: GoogleFonts.dmSans(
//                                           fontWeight: isNow
//                                               ? FontWeight.w700
//                                               : FontWeight.w500,
//                                         ),
//                                         color: isNow
//                                             ? const Color(0xFF1976D2)
//                                             : const Color(0xFF2B2B2B),
//                                         fontSize: 12.0,
//                                         letterSpacing: 0.0,
//                                       ),
//                                 ),
//                               ].divide(const SizedBox(height: 4.0)),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 ].divide(const SizedBox(height: 12.0)),
//               ),
//             ),
//           );
//         },
//       );
//     });
//   }
// }
