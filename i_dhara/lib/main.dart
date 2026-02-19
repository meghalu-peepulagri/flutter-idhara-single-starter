import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/config/env.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/routes/app_pages.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app/core/flutter_flow/flutter_flow_theme.dart';
import 'app/core/flutter_flow/flutter_flow_util.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebasemessageBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // On iOS, notification messages are shown automatically by APNs.
  // We only need to handle data-only messages manually here.
  // For Android, show a local notification for all background messages.
  if (!Platform.isIOS) {
    final FlutterLocalNotificationsPlugin bgPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@drawable/ic_notification');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await bgPlugin.initialize(initSettings);

    final notification = message.notification;
    if (notification != null) {
      Map<String, dynamic> fullData = Map<String, dynamic>.from(message.data);
      fullData['title'] = notification.title ?? '';
      fullData['body'] = notification.body ?? '';

      await bgPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
            icon: '@drawable/idhara_logo',
            color: Color(0xFF1B5E8A),
          ),
        ),
        payload: json.encode(fullData),
      );
    }
  }
}

Future<void> _requestFCMPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  debugPrint('FCM Permission: ${settings.authorizationStatus}');
}

Future<void> _requestNotificationPermission() async {
  try {
    var status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      if (result.isPermanentlyDenied) {
        openAppSettings();
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  } catch (e) {
    debugPrint('Error requesting notification permission: $e');
  }
}

void _handleNotificationTap(String? payload) {
  print("line --->");
  if (payload == null || payload.isEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(Routes.dashboard);
    });
    return;
  }
  try {
    Map<String, dynamic> data = json.decode(payload);
    print("line 66 $payload");
    String title = data['title'] ?? "";
    String? body = data['body'];
    String motorId = data['motor_id'];
    String starterId = data['starter_id'];
    int motorId0 = int.parse(motorId);
    int starterId0 = int.parse(starterId);
    if (starterId.isNotEmpty) {
      SharedPreference.setStarterId(starterId0);
      print("line 75 starter $starterId0");
    }

    if (title.toLowerCase().contains("state") && title.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(Routes.dashboard);
      });
    } else if (title.toLowerCase().contains("mode") && title.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SharedPreference.setMotorId(motorId0);
        Get.offAllNamed(Routes.motorDetails, arguments: {'tabIndex': 0});
      });
    } else if (title.toLowerCase().contains("fault") && title.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SharedPreference.setMotorId(motorId0);
        Get.offAllNamed(Routes.motorDetails,
            arguments: {'tabIndex': 2, 'logFilter': 'Faults'});
      });
    } else if (title.toLowerCase().contains("alert") && title.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SharedPreference.setMotorId(motorId0);
        Get.offAllNamed(Routes.motorDetails,
            arguments: {'tabIndex': 2, 'logFilter': 'Alerts'});
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SharedPreference.clear();
        Get.offAllNamed(Routes.loginwithmobile);
      });
    }
  } catch (e) {
    SharedPreference.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(Routes.loginwithmobile);
    });
  }
}

Future<void> _setupLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_notification');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: false, // We handle permission separately
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
    _handleNotificationTap(response.payload);
  });
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
      'high_importance_channel', 'High Importance Notifications',
      importance: Importance.high);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await SharedPreference.init();
    usePathUrlStrategy();
    await FlutterFlowTheme.initialize();
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };
    runApp(const MyWebApp());
  } else {
    // Load environment variables
    try {
      await dotenv.load(fileName: '.env');
      AppEnvironment.setup();
    } catch (e) {
      debugPrint('Error loading .env file: $e');
    }

    // Initialize SharedPreference BEFORE Firebase
    await SharedPreference.init();

    RemoteMessage? initialMessage;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebasemessageBackgroundHandler);

      initialMessage = await FirebaseMessaging.instance.getInitialMessage();

      // Request FCM permission first
      await _requestFCMPermission();

      // iOS: Must set foreground options BEFORE getting token
      if (Platform.isIOS) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      await _setupLocalNotifications();
      await _requestNotificationPermission();

      // iOS: Wait for APNS token before getting FCM token
      if (Platform.isIOS) {
        String? apnsToken;
        for (int i = 0; i < 15; i++) {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(milliseconds: 500));
        }
        debugPrint('APNS Token: $apnsToken');
        if (apnsToken == null) {
          debugPrint('WARNING: APNS token is null - FCM token will also be null');
        }
      }

      // Get and store FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM Token: $fcmToken');
      if (fcmToken != null) {
        SharedPreference.setFcmToken(fcmToken);
      }

      // CRITICAL: Listen for token refresh and update stored token
      // This fixes "normal send not working" - token changes and server gets stale token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token Refreshed: $newToken');
        SharedPreference.setFcmToken(newToken);
      });
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }

    GoRouter.optionURLReflectsImperativeAPIs = true;
    usePathUrlStrategy();

    await FlutterFlowTheme.initialize();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    runApp(MyApp(
      initialMessage: initialMessage,
    ));
  }
}

class MyApp extends StatefulWidget {
  final RemoteMessage? initialMessage;
  const MyApp({super.key, this.initialMessage});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Foreground message handler
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showLocalNotification(message);
        });

        // App opened from background via notification
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleInitialMessage(message);
        });

        // App launched from terminated state via notification
        if (widget.initialMessage != null) {
          _handleInitialMessage(widget.initialMessage!);
        }

        // Handle local notification tap (app was terminated)
        final NotificationAppLaunchDetails? details =
            await flutterLocalNotificationsPlugin
                .getNotificationAppLaunchDetails();
        if (details?.didNotificationLaunchApp == true &&
            details!.notificationResponse != null) {
          _handleNotificationTap(details.notificationResponse!.payload);
        }
      } catch (e) {
        debugPrint("line error --------------> $e");
      }
    });
  }

  void _handleInitialMessage(RemoteMessage message) {
    Map<String, dynamic> fullData = Map<String, dynamic>.from(message.data);
    fullData['title'] = message.notification?.title ?? '';
    fullData['body'] = message.notification?.body ?? '';
    _handleNotificationTap(json.encode(fullData));
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      Map<String, dynamic> fullData = Map<String, dynamic>.from(message.data);
      fullData['title'] = notification.title ?? '';
      fullData['body'] = notification.body ?? '';
      flutterLocalNotificationsPlugin
          .show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                importance: Importance.max,
                priority: Priority.high,
                showWhen: false,
                icon: '@drawable/idhara_logo',
                color: Color(0xFF1B5E8A),
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: json.encode(fullData),
          )
          .catchError((e) {});
    }
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'I Dhara',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      initialRoute: SharedPreference.getAccessToken().isNotEmpty
          ? Routes.dashboard
          : Routes.splash,
      getPages: AppPages.getPages,
    );
  }
}

class MyWebApp extends StatefulWidget {
  const MyWebApp({super.key});

  @override
  State<MyWebApp> createState() => _MyWebAppState();

  static _MyWebAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyWebAppState>()!;
}

class _MyWebAppState extends State<MyWebApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  @override
  void initState() {
    super.initState();
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Peepul Agri',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      initialRoute: SharedPreference.getAccessToken().isNotEmpty
          ? Routes.dashboard
          : Routes.splash,
      getPages: AppPages.getPages,
    );
  }
}
