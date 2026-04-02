// flutter build apk --dart-define=ENV=live
// flutter build apk --dart-define=ENV=staging
// flutter build apk --dart-define=ENV=dev

import 'dart:convert';

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
import 'package:i_dhara/app/core/services/connectivity_service.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/routes/app_pages.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app/core/flutter_flow/flutter_flow_theme.dart';
import 'app/core/flutter_flow/flutter_flow_util.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebasemessageBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Show local notification with iDhara logo in background
  final FlutterLocalNotificationsPlugin bgPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@drawable/ic_notification');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit, iOS: iosInit);
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

Future<void> _requestFCMPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings =
      await messaging.requestPermission(alert: true, badge: true, sound: true);
  if (settings.authorizationStatus == AuthorizationStatus.denied) {}
}

Future<void> _requestNotificationPermission() async {
  try {
    var status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      if (result.isPermanentlyDenied) {
        openAppSettings();
      }
      // Removed recursive call that caused infinite loop in release builds
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
  if (payload == null || payload.isEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(
          Routes.dashboard); // Changed: Use offAllNamed to clear stack
    });
    return;
  }
  try {
    Map<String, dynamic> data = json.decode(payload);
    String title = data['title'] ?? "";
    String? body = data['body'];
    String motorId = data['motor_id'];
    String starterId = data['starter_id'];
    int motorId0 = int.parse(motorId);
    int starterId0 = int.parse(starterId);
    if (starterId.isNotEmpty) {
      SharedPreference.setStarterId(starterId0);
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
        Get.offAllNamed(Routes.dashboard);
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
      DarwinInitializationSettings();
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
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };
    runApp(const MyWebApp());
  } else {
    // Load environment variables with error handling
    try {
      await dotenv.load(fileName: '.env');
      AppEnvironment.setup();
    } catch (e) {
      debugPrint('Error loading .env file: $e');
    }

    // Initialize SharedPreference BEFORE Firebase to ensure FCM token can be saved
    await SharedPreference.init();

    // Initialize Firebase with error handling
    RemoteMessage? initialMessage;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebasemessageBackgroundHandler);
      initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      await _requestFCMPermission();
      await _setupLocalNotifications();
      await _requestNotificationPermission();
      FirebaseMessaging.instance.getToken().then((value) {
        SharedPreference.setFcmToken(value.toString());
      });
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
    }

    GoRouter.optionURLReflectsImperativeAPIs = true;
    usePathUrlStrategy();

    await FlutterFlowTheme.initialize();
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // For Android
        statusBarBrightness: Brightness.light, // For iOS
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
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

  // This widget is the root of your application.
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
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showLocalNotification(message);
        });
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleInitialMessage(message);
        });
        if (widget.initialMessage != null) {
          _handleInitialMessage(widget.initialMessage!);
        }
        final NotificationAppLaunchDetails? details =
            await flutterLocalNotificationsPlugin
                .getNotificationAppLaunchDetails();
        if (details?.didNotificationLaunchApp == true &&
            details!.notificationResponse != null) {
          _handleNotificationTap(details.notificationResponse!.payload);
        }
      } catch (e) {
        print("line error --------------> $e");
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
    // Get title & body from notification OR fallback to data
    String? title = message.notification?.title ?? message.data['title'];
    String? body = message.notification?.body ?? message.data['body'];

    if (title != null && body != null) {
      Map<String, dynamic> fullData = Map<String, dynamic>.from(message.data);

      fullData['title'] = title;
      fullData['body'] = body;

      flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body, // ✅ Body will now always show
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@drawable/idhara_logo',
            color: Color(0xFF1B5E8A),
            styleInformation: BigTextStyleInformation(
              '', // Will auto expand large text
            ),
          ),
        ),
        payload: json.encode(fullData),
      );
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
