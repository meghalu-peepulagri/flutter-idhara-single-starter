// import 'dart:async';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
// import 'package:i_dhara/app/data/services/weather_service/weather_services.dart';

// class WeatherCard extends StatefulWidget {
//   const WeatherCard({super.key});

//   @override
//   State<WeatherCard> createState() => _WeatherCardState();
// }

// class _WeatherCardState extends State<WeatherCard> with WidgetsBindingObserver {
//   final WeatherService _weatherService = WeatherService();
//   WeatherData? _weatherData;
//   bool _isLoading = true;
//   LocationPermissionStatus? _permissionStatus;
//   bool _hasRequestedPermission = false;
//   Timer? _hourCheckTimer;
//   StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _requestLocationPermissionDirectly();
//     _startHourCheckTimer();
//     _listenToLocationServiceChanges();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _hourCheckTimer?.cancel();
//     _serviceStatusSubscription?.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // When app resumes from settings, reload weather data
//     if (state == AppLifecycleState.resumed) {
//       _loadWeatherData();
//     }
//   }

//   void _startHourCheckTimer() {
//     // Check every minute if the hour has changed
//     _hourCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
//       if (mounted) {
//         setState(() {
//           // This will trigger a rebuild and update the "Now" indicator
//         });
//       }
//     });
//   }

//   void _listenToLocationServiceChanges() {
//     // Listen to location service status changes
//     _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
//       (ServiceStatus status) {
//         if (status == ServiceStatus.enabled) {
//           // Location service turned on, reload data
//           _loadWeatherData();
//         } else {
//           // Location service turned off
//           setState(() {
//             _permissionStatus = LocationPermissionStatus.serviceDisabled;
//             _weatherData = null;
//           });
//         }
//       },
//     );
//   }

//   Future<void> _requestLocationPermissionDirectly() async {
//     setState(() => _isLoading = true);

//     // Check if location service is enabled
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       setState(() {
//         _permissionStatus = LocationPermissionStatus.serviceDisabled;
//         _isLoading = false;
//       });
//       return;
//     }

//     // Check current permission status
//     LocationPermission permission = await Geolocator.checkPermission();

//     if (permission == LocationPermission.denied && !_hasRequestedPermission) {
//       // Request permission directly - this will show the system dialog
//       _hasRequestedPermission = true;
//       permission = await Geolocator.requestPermission();
//     }

//     // Handle the permission result
//     if (permission == LocationPermission.denied) {
//       setState(() {
//         _permissionStatus = LocationPermissionStatus.denied;
//         _isLoading = false;
//       });
//     } else if (permission == LocationPermission.deniedForever) {
//       setState(() {
//         _permissionStatus = LocationPermissionStatus.deniedForever;
//         _isLoading = false;
//       });
//     } else {
//       // Permission granted - load weather data
//       setState(() {
//         _permissionStatus = LocationPermissionStatus.granted;
//       });
//       await _loadWeatherDataAfterPermission();
//     }
//   }

//   Future<void> _loadWeatherData() async {
//     setState(() => _isLoading = true);

//     final status = await _weatherService.handleLocationPermission();
//     setState(() {
//       _permissionStatus = status;
//     });

//     if (status == LocationPermissionStatus.granted) {
//       final weatherData = await _weatherService.getWeatherData();
//       setState(() {
//         _weatherData = weatherData;
//         _isLoading = false;
//       });
//     } else {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _loadWeatherDataAfterPermission() async {
//     final weatherData = await _weatherService.getWeatherData();
//     setState(() {
//       _weatherData = weatherData;
//       _isLoading = false;
//     });
//   }

//   Future<void> _handleEnableLocation() async {
//     if (_permissionStatus == LocationPermissionStatus.deniedForever) {
//       // Open app settings if permission is permanently denied
//       await Geolocator.openAppSettings();
//     } else if (_permissionStatus == LocationPermissionStatus.serviceDisabled) {
//       // Open location settings if service is disabled
//       await Geolocator.openLocationSettings();
//     } else {
//       // For first time denial, request permission again
//       await _requestLocationPermissionDirectly();
//     }
//   }

//   String _getPermissionMessage() {
//     switch (_permissionStatus) {
//       case LocationPermissionStatus.deniedForever:
//         return 'Location permission permanently denied.\nPlease enable it from Settings.';
//       case LocationPermissionStatus.denied:
//       default:
//         return 'Enable location to see weather forecast';
//     }
//   }

//   String _getButtonText() {
//     switch (_permissionStatus) {
//       case LocationPermissionStatus.deniedForever:
//         return 'Open Settings';
//       case LocationPermissionStatus.serviceDisabled:
//         return 'Enable Location';
//       default:
//         return 'Enable Location';
//     }
//   }

//   String _getTimeFormat(DateTime time) {
//     final now = DateTime.now();

//     // If it's the current hour, show "Now"
//     if (time.hour == now.hour && time.day == now.day) {
//       return 'Now';
//     }

//     // Format as 24-hour time (e.g., "14:00", "15:00" HH:mm)
//     return DateFormat('h a').format(time);
//   }

//   bool _isCurrentHour(DateTime time) {
//     final now = DateTime.now();
//     return time.hour == now.hour && time.day == now.day;
//   }

//   HourlyForecast? _getCurrentHourForecast() {
//     if (_weatherData == null) return null;

//     final now = DateTime.now();
//     for (var forecast in _weatherData!.hourlyForecast) {
//       if (forecast.time.hour == now.hour && forecast.time.day == now.day) {
//         return forecast;
//       }
//     }

//     // If current hour not found, return first forecast
//     return _weatherData!.hourlyForecast.isNotEmpty
//         ? _weatherData!.hourlyForecast.first
//         : null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     // if (_isLoading) {
//     //   return Container(
//     //     height: 200,
//     //     decoration: BoxDecoration(
//     //       color: Colors.white,
//     //       borderRadius: BorderRadius.circular(10.0),
//     //     ),
//     //     child: const Center(
//     //       child: CircularProgressIndicator(),
//     //     ),
//     //   );
//     // }

//     if (_permissionStatus != LocationPermissionStatus.granted ||
//         _weatherData == null) {
//       return Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10.0),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 _permissionStatus == LocationPermissionStatus.serviceDisabled
//                     ? Icons.location_disabled
//                     : Icons.location_off,
//                 size: 48,
//                 color: Colors.grey[400],
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Location Permission Required',
//                 style: FlutterFlowTheme.of(context).bodyMedium.override(
//                       font: GoogleFonts.dmSans(
//                         fontWeight: FontWeight.w600,
//                       ),
//                       color: const Color(0xFF121212),
//                       fontSize: 14.0,
//                     ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _getPermissionMessage(),
//                 textAlign: TextAlign.center,
//                 style: FlutterFlowTheme.of(context).bodyMedium.override(
//                       font: GoogleFonts.dmSans(),
//                       color: const Color(0xFF8C8C8C),
//                       fontSize: 12.0,
//                     ),
//               ),
//               const SizedBox(height: 12),
//               ElevatedButton.icon(
//                 onPressed: _handleEnableLocation,
//                 icon: Icon(
//                   _permissionStatus == LocationPermissionStatus.deniedForever
//                       ? Icons.settings
//                       : Icons.location_on,
//                   size: 20,
//                 ),
//                 label: Text(_getButtonText()),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF4CAF50),
//                   foregroundColor: Colors.white,
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final currentForecast = _getCurrentHourForecast();

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       child: Padding(
//         padding: const EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 10.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.max,
//           children: [
//             Padding(
//               padding:
//                   const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
//               child: Row(
//                 mainAxisSize: MainAxisSize.max,
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Today\'s Forecast - ${_weatherData!.location}',
//                       style: FlutterFlowTheme.of(context).bodyMedium.override(
//                             font: GoogleFonts.dmSans(
//                               fontWeight: FontWeight.w500,
//                             ),
//                             color: const Color(0xFF121212),
//                             fontSize: 12.0,
//                             letterSpacing: 0.0,
//                           ),
//                     ),
//                   ),
//                   if (currentForecast != null)
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         CachedNetworkImage(
//                           imageUrl: 'https:${currentForecast.icon}',
//                           width: 24,
//                           height: 24,
//                           fit: BoxFit.cover,
//                           placeholder: (context, url) => const SizedBox(
//                             width: 24,
//                             height: 24,
//                             child: Center(
//                               child: SizedBox(
//                                 width: 12,
//                                 height: 12,
//                                 child:
//                                     CircularProgressIndicator(strokeWidth: 2),
//                               ),
//                             ),
//                           ),
//                           errorWidget: (context, url, error) =>
//                               const Icon(Icons.error, size: 24),
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${currentForecast.tempC.round()}°C',
//                           style:
//                               FlutterFlowTheme.of(context).bodyMedium.override(
//                                     font: GoogleFonts.dmSans(
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                     color: const Color(0xFF1976D2),
//                                     fontSize: 14.0,
//                                     letterSpacing: 0.0,
//                                   ),
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//             ),
//             Container(
//               width: double.infinity,
//               height: 80.0,
//               decoration: const BoxDecoration(),
//               child: Padding(
//                 padding:
//                     const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
//                 child: ListView.separated(
//                   padding: EdgeInsets.zero,
//                   shrinkWrap: true,
//                   scrollDirection: Axis.horizontal,
//                   itemCount: _weatherData!.hourlyForecast.length,
//                   separatorBuilder: (context, index) => const Row(
//                     mainAxisSize: MainAxisSize.max,
//                     children: [
//                       SizedBox(
//                         height: 50.0,
//                         child: VerticalDivider(
//                           thickness: 1.0,
//                           color: Color(0x1A000000),
//                         ),
//                       ),
//                     ],
//                   ),
//                   itemBuilder: (context, index) {
//                     final forecast = _weatherData!.hourlyForecast[index];
//                     final isNow = _isCurrentHour(forecast.time);

//                     return Container(
//                       decoration: BoxDecoration(
//                         color: isNow
//                             ? const Color(0xFFE3F2FD)
//                             : Colors.transparent,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 4),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.max,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             _getTimeFormat(forecast.time),
//                             style: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .override(
//                                   font: GoogleFonts.dmSans(
//                                     fontWeight: isNow
//                                         ? FontWeight.w700
//                                         : FontWeight.w500,
//                                   ),
//                                   color: isNow
//                                       ? const Color(0xFF1976D2)
//                                       : const Color(0xFF8C8C8C),
//                                   fontSize: 12.0,
//                                   letterSpacing: 0.0,
//                                 ),
//                           ),
//                           CachedNetworkImage(
//                             imageUrl: 'https:${forecast.icon}',
//                             width: 32,
//                             height: 32,
//                             fit: BoxFit.cover,
//                             placeholder: (context, url) => const SizedBox(
//                               width: 32,
//                               height: 32,
//                               child: Center(
//                                 child: SizedBox(
//                                   width: 16,
//                                   height: 16,
//                                   child:
//                                       CircularProgressIndicator(strokeWidth: 2),
//                                 ),
//                               ),
//                             ),
//                             errorWidget: (context, url, error) =>
//                                 const Icon(Icons.error, size: 32),
//                           ),
//                           Text(
//                             '${forecast.tempC.round()}°C',
//                             style: FlutterFlowTheme.of(context)
//                                 .bodyMedium
//                                 .override(
//                                   font: GoogleFonts.dmSans(
//                                     fontWeight: isNow
//                                         ? FontWeight.w700
//                                         : FontWeight.w500,
//                                   ),
//                                   color: isNow
//                                       ? const Color(0xFF1976D2)
//                                       : const Color(0xFF2B2B2B),
//                                   fontSize: 12.0,
//                                   letterSpacing: 0.0,
//                                 ),
//                           ),
//                         ].divide(const SizedBox(height: 4.0)),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ].divide(const SizedBox(height: 12.0)),
//         ),
//       ),
//     );
//   }
// }

// import 'dart:async';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_theme.dart';
// import 'package:i_dhara/app/core/flutter_flow/flutter_flow_util.dart';
// import 'package:i_dhara/app/data/services/weather_service/weather_services.dart';

// class WeatherCard extends StatefulWidget {
//   const WeatherCard({super.key});

//   @override
//   State<WeatherCard> createState() => _WeatherCardState();
// }

// class _WeatherCardState extends State<WeatherCard> with WidgetsBindingObserver {
//   final WeatherService _weatherService = WeatherService();
//   WeatherData? _weatherData;
//   LocationPermissionStatus? _permissionStatus;
//   bool _hasRequestedPermission = false;
//   Timer? _hourCheckTimer;
//   StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
//   bool _isInitializing = true;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeWeatherCard();
//     _startHourCheckTimer();
//     _listenToLocationServiceChanges();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _hourCheckTimer?.cancel();
//     _serviceStatusSubscription?.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // When app resumes from settings, reload weather data
//     if (state == AppLifecycleState.resumed) {
//       _initializeWeatherCard();
//     }
//   }

//   void _startHourCheckTimer() {
//     // Check every minute if the hour has changed
//     _hourCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
//       if (mounted) {
//         setState(() {
//           // This will trigger a rebuild and update the "Now" indicator
//         });
//       }
//     });
//   }

//   void _listenToLocationServiceChanges() {
//     // Listen to location service status changes
//     _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
//       (ServiceStatus status) {
//         if (status == ServiceStatus.enabled) {
//           // Location service turned on, reload data
//           _initializeWeatherCard();
//         } else {
//           // Location service turned off
//           setState(() {
//             _permissionStatus = LocationPermissionStatus.serviceDisabled;
//             _weatherData = null;
//             _isInitializing = false;
//           });
//         }
//       },
//     );
//   }

//   Future<void> _initializeWeatherCard() async {
//     setState(() => _isInitializing = true);

//     // Check if location service is enabled
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       setState(() {
//         _permissionStatus = LocationPermissionStatus.serviceDisabled;
//         _isInitializing = false;
//       });
//       return;
//     }

//     // Check current permission status
//     LocationPermission permission = await Geolocator.checkPermission();

//     if (permission == LocationPermission.denied) {
//       setState(() {
//         _permissionStatus = LocationPermissionStatus.denied;
//         _isInitializing = false;
//       });
//       return;
//     }

//     if (permission == LocationPermission.deniedForever) {
//       setState(() {
//         _permissionStatus = LocationPermissionStatus.deniedForever;
//         _isInitializing = false;
//       });
//       return;
//     }

//     // Permission granted - load weather data directly
//     setState(() {
//       _permissionStatus = LocationPermissionStatus.granted;
//     });

//     final weatherData = await _weatherService.getWeatherData();
//     setState(() {
//       _weatherData = weatherData;
//       _isInitializing = false;
//     });
//   }

//   Future<void> _handleEnableLocation() async {
//     if (_permissionStatus == LocationPermissionStatus.deniedForever) {
//       // Open app settings if permission is permanently denied
//       await Geolocator.openAppSettings();
//     } else if (_permissionStatus == LocationPermissionStatus.serviceDisabled) {
//       // Open location settings if service is disabled
//       await Geolocator.openLocationSettings();
//     } else if (_permissionStatus == LocationPermissionStatus.denied) {
//       // Request permission
//       _hasRequestedPermission = true;
//       LocationPermission permission = await Geolocator.requestPermission();

//       if (permission == LocationPermission.denied) {
//         setState(() {
//           _permissionStatus = LocationPermissionStatus.denied;
//         });
//       } else if (permission == LocationPermission.deniedForever) {
//         setState(() {
//           _permissionStatus = LocationPermissionStatus.deniedForever;
//         });
//       } else {
//         // Permission granted - load weather data
//         setState(() {
//           _permissionStatus = LocationPermissionStatus.granted;
//           _isInitializing = true;
//         });

//         final weatherData = await _weatherService.getWeatherData();
//         setState(() {
//           _weatherData = weatherData;
//           _isInitializing = false;
//         });
//       }
//     }
//   }

//   String _getPermissionMessage() {
//     switch (_permissionStatus) {
//       case LocationPermissionStatus.deniedForever:
//         return 'Location permission permanently denied.\nPlease enable it from Settings.';
//       case LocationPermissionStatus.serviceDisabled:
//         return 'Location service is disabled.\nPlease enable it to see weather.';
//       case LocationPermissionStatus.denied:
//       default:
//         return 'Enable location to see weather forecast';
//     }
//   }

//   String _getButtonText() {
//     switch (_permissionStatus) {
//       case LocationPermissionStatus.deniedForever:
//         return 'Open Settings';
//       case LocationPermissionStatus.serviceDisabled:
//         return 'Enable Location';
//       default:
//         return 'Enable Location';
//     }
//   }

//   String _getTimeFormat(DateTime time) {
//     final now = DateTime.now();

//     // If it's the current hour, show "Now"
//     if (time.hour == now.hour && time.day == now.day) {
//       return 'Now';
//     }

//     // Format as 24-hour time (e.g., "14:00", "15:00" HH:mm)
//     return DateFormat('h a').format(time);
//   }

//   bool _isCurrentHour(DateTime time) {
//     final now = DateTime.now();
//     return time.hour == now.hour && time.day == now.day;
//   }

//   HourlyForecast? _getCurrentHourForecast() {
//     if (_weatherData == null) return null;

//     final now = DateTime.now();
//     for (var forecast in _weatherData!.hourlyForecast) {
//       if (forecast.time.hour == now.hour && forecast.time.day == now.day) {
//         return forecast;
//       }
//     }

//     // If current hour not found, return first forecast
//     return _weatherData!.hourlyForecast.isNotEmpty
//         ? _weatherData!.hourlyForecast.first
//         : null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 140.0,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10.0),
//       ),
//       child: _isInitializing
//           ? const Center(
//               child: SizedBox(
//                 width: 24,
//                 height: 24,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//             )
//           : (_permissionStatus != LocationPermissionStatus.granted ||
//                   _weatherData == null)
//               ? _buildPermissionUI()
//               : _buildWeatherContent(),
//     );
//   }

//   Widget _buildPermissionUI() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//       child: Row(
//         children: [
//           Icon(
//             _permissionStatus == LocationPermissionStatus.serviceDisabled
//                 ? Icons.location_disabled
//                 : Icons.location_off,
//             size: 36,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Location Permission Required',
//                   style: FlutterFlowTheme.of(context).bodyMedium.override(
//                         font: GoogleFonts.dmSans(
//                           fontWeight: FontWeight.w600,
//                         ),
//                         color: const Color(0xFF121212),
//                         fontSize: 13.0,
//                       ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   _getPermissionMessage(),
//                   style: FlutterFlowTheme.of(context).bodyMedium.override(
//                         font: GoogleFonts.dmSans(),
//                         color: const Color(0xFF8C8C8C),
//                         fontSize: 11.0,
//                       ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
//           ElevatedButton(
//             onPressed: _handleEnableLocation,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF4CAF50),
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               minimumSize: const Size(0, 0),
//             ),
//             child: Text(
//               _getButtonText(),
//               style: const TextStyle(fontSize: 12),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWeatherContent() {
//     final currentForecast = _getCurrentHourForecast();

//     return Padding(
//       padding: const EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 10.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.max,
//         children: [
//           Padding(
//             padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
//             child: Row(
//               mainAxisSize: MainAxisSize.max,
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Text(
//                     'Today\'s Forecast - ${_weatherData!.location}',
//                     style: FlutterFlowTheme.of(context).bodyMedium.override(
//                           font: GoogleFonts.dmSans(
//                             fontWeight: FontWeight.w500,
//                           ),
//                           color: const Color(0xFF121212),
//                           fontSize: 12.0,
//                           letterSpacing: 0.0,
//                         ),
//                   ),
//                 ),
//                 if (currentForecast != null)
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CachedNetworkImage(
//                         imageUrl: 'https:${currentForecast.icon}',
//                         width: 24,
//                         height: 24,
//                         fit: BoxFit.cover,
//                         placeholder: (context, url) => const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: Center(
//                             child: SizedBox(
//                               width: 12,
//                               height: 12,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             ),
//                           ),
//                         ),
//                         errorWidget: (context, url, error) =>
//                             const Icon(Icons.error, size: 24),
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         '${currentForecast.tempC.round()}°C',
//                         style: FlutterFlowTheme.of(context).bodyMedium.override(
//                               font: GoogleFonts.dmSans(
//                                 fontWeight: FontWeight.w600,
//                               ),
//                               color: const Color(0xFF1976D2),
//                               fontSize: 14.0,
//                               letterSpacing: 0.0,
//                             ),
//                       ),
//                     ],
//                   ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Padding(
//               padding:
//                   const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
//               child: ListView.separated(
//                 padding: EdgeInsets.zero,
//                 shrinkWrap: true,
//                 scrollDirection: Axis.horizontal,
//                 itemCount: _weatherData!.hourlyForecast.length,
//                 separatorBuilder: (context, index) => const Row(
//                   mainAxisSize: MainAxisSize.max,
//                   children: [
//                     SizedBox(
//                       height: 50.0,
//                       child: VerticalDivider(
//                         thickness: 1.0,
//                         color: Color(0x1A000000),
//                       ),
//                     ),
//                   ],
//                 ),
//                 itemBuilder: (context, index) {
//                   final forecast = _weatherData!.hourlyForecast[index];
//                   final isNow = _isCurrentHour(forecast.time);

//                   return Container(
//                     decoration: BoxDecoration(
//                       color:
//                           isNow ? const Color(0xFFE3F2FD) : Colors.transparent,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.max,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           _getTimeFormat(forecast.time),
//                           style: FlutterFlowTheme.of(context)
//                               .bodyMedium
//                               .override(
//                                 font: GoogleFonts.dmSans(
//                                   fontWeight:
//                                       isNow ? FontWeight.w700 : FontWeight.w500,
//                                 ),
//                                 color: isNow
//                                     ? const Color(0xFF1976D2)
//                                     : const Color(0xFF8C8C8C),
//                                 fontSize: 12.0,
//                                 letterSpacing: 0.0,
//                               ),
//                         ),
//                         CachedNetworkImage(
//                           imageUrl: 'https:${forecast.icon}',
//                           width: 32,
//                           height: 32,
//                           fit: BoxFit.cover,
//                           placeholder: (context, url) => const SizedBox(
//                             width: 32,
//                             height: 32,
//                             child: Center(
//                               child: SizedBox(
//                                 width: 16,
//                                 height: 16,
//                                 child:
//                                     CircularProgressIndicator(strokeWidth: 2),
//                               ),
//                             ),
//                           ),
//                           errorWidget: (context, url, error) =>
//                               const Icon(Icons.error, size: 32),
//                         ),
//                         Text(
//                           '${forecast.tempC.round()}°C',
//                           style: FlutterFlowTheme.of(context)
//                               .bodyMedium
//                               .override(
//                                 font: GoogleFonts.dmSans(
//                                   fontWeight:
//                                       isNow ? FontWeight.w700 : FontWeight.w500,
//                                 ),
//                                 color: isNow
//                                     ? const Color(0xFF1976D2)
//                                     : const Color(0xFF2B2B2B),
//                                 fontSize: 12.0,
//                                 letterSpacing: 0.0,
//                               ),
//                         ),
//                       ].divide(const SizedBox(height: 4.0)),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ].divide(const SizedBox(height: 12.0)),
//       ),
//     );
//   }
// }

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
  LocationPermissionStatus? _permissionStatus;
  bool _hasRequestedPermission = false;
  Timer? _hourCheckTimer;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  bool _isInitializing = false;

  // Cache management
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
    // When app resumes from background/settings
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshIfNeeded();
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
          // Location service turned on, refresh data
          _forceRefresh();
        } else {
          // Location service turned off
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

    // Cache is valid if less than 1 hour has passed
    return difference < _cacheDuration;
  }

  void _checkAndRefreshIfNeeded() {
    if (_isCacheValid()) {
      // Cache is still valid, use cached data
      debugPrint('✅ Weather cache is valid, using cached data');
      setState(() {
        _weatherData = _cachedWeatherData;
        _permissionStatus = _cachedPermissionStatus;
        _isInitializing = false;
      });
    } else {
      // Cache expired, refresh data
      debugPrint('⏰ Weather cache expired (1 hour passed), refreshing...');
      _forceRefresh();
    }
  }

  Future<void> _forceRefresh() async {
    setState(() => _isInitializing = true);

    // Clear cache
    _lastFetchTime = null;
    _cachedWeatherData = null;
    _cachedPermissionStatus = null;

    await _initializeWeatherCard();
  }

  Future<void> _initializeWeatherCard() async {
    // Check if we have valid cached data
    if (_isCacheValid() && !_isInitializing) {
      debugPrint('✅ Using cached weather data');
      setState(() {
        _weatherData = _cachedWeatherData;
        _permissionStatus = _cachedPermissionStatus;
      });
      return;
    }

    // If cache expired or no cache, fetch new data
    if (!_isInitializing) {
      setState(() => _isInitializing = true);
    }

    debugPrint('🔄 Fetching fresh weather data...');

    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _permissionStatus = LocationPermissionStatus.serviceDisabled;
        _cachedPermissionStatus = LocationPermissionStatus.serviceDisabled;
        _isInitializing = false;
      });
      return;
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      setState(() {
        _permissionStatus = LocationPermissionStatus.denied;
        _cachedPermissionStatus = LocationPermissionStatus.denied;
        _isInitializing = false;
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionStatus = LocationPermissionStatus.deniedForever;
        _cachedPermissionStatus = LocationPermissionStatus.deniedForever;
        _isInitializing = false;
      });
      return;
    }

    // Permission granted - load weather data directly
    setState(() {
      _permissionStatus = LocationPermissionStatus.granted;
      _cachedPermissionStatus = LocationPermissionStatus.granted;
    });

    final weatherData = await _weatherService.getWeatherData();

    if (weatherData != null) {
      // Update cache
      _lastFetchTime = DateTime.now();
      _cachedWeatherData = weatherData;

      debugPrint('✅ Weather data fetched and cached at $_lastFetchTime');
      debugPrint(
          '⏰ Next refresh will be at ${_lastFetchTime!.add(_cacheDuration)}');
    }

    setState(() {
      _weatherData = weatherData;
      _isInitializing = false;
    });
  }

  Future<void> _handleEnableLocation() async {
    if (_permissionStatus == LocationPermissionStatus.deniedForever) {
      // Open app settings if permission is permanently denied
      await Geolocator.openAppSettings();
    } else if (_permissionStatus == LocationPermissionStatus.serviceDisabled) {
      // Open location settings if service is disabled
      await Geolocator.openLocationSettings();
    } else if (_permissionStatus == LocationPermissionStatus.denied) {
      // Request permission
      _hasRequestedPermission = true;
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        setState(() {
          _permissionStatus = LocationPermissionStatus.denied;
          _cachedPermissionStatus = LocationPermissionStatus.denied;
        });
      } else if (permission == LocationPermission.deniedForever) {
        setState(() {
          _permissionStatus = LocationPermissionStatus.deniedForever;
          _cachedPermissionStatus = LocationPermissionStatus.deniedForever;
        });
      } else {
        // Permission granted - fetch fresh data
        await _forceRefresh();
      }
    }
  }

  String _getPermissionMessage() {
    switch (_permissionStatus) {
      case LocationPermissionStatus.deniedForever:
        return 'Location permission permanently denied.\nPlease enable it from Settings.';
      case LocationPermissionStatus.serviceDisabled:
        return 'Location service is disabled.\nPlease enable it to see weather.';
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
    return Container(
      height: 140.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(
            _permissionStatus == LocationPermissionStatus.serviceDisabled
                ? Icons.location_disabled
                : Icons.location_off,
            size: 36,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Permission Required',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                        ),
                        color: const Color(0xFF121212),
                        fontSize: 13.0,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getPermissionMessage(),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.dmSans(),
                        color: const Color(0xFF8C8C8C),
                        fontSize: 11.0,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _handleEnableLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(0, 0),
            ),
            child: Text(
              _getButtonText(),
              style: const TextStyle(fontSize: 12),
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
          Expanded(
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
                      color:
                          isNow ? const Color(0xFFE3F2FD) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                  fontWeight:
                                      isNow ? FontWeight.w700 : FontWeight.w500,
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
                                  fontWeight:
                                      isNow ? FontWeight.w700 : FontWeight.w500,
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
    );
  }
}
