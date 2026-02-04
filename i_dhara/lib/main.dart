import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:i_dhara/app/core/config/env.dart';
import 'package:i_dhara/app/data/services/storages/shared_preference.dart';
import 'package:i_dhara/app/presentation/routes/app_pages.dart';
import 'package:i_dhara/app/presentation/routes/app_routes.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app/core/flutter_flow/flutter_flow_theme.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebasemessageBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> _requestFCMPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> _requestNotificationPermission() async {
  if (kIsWeb) return;
  var status = await Permission.notification.status;
  if (status.isDenied) {
    final result = await Permission.notification.request();
    if (result.isPermanentlyDenied) {
      openAppSettings();
    }
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
  }
  if (!kIsWeb && Platform.isIOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}

Future<void> _setupLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      _handleNotificationTap(response.payload);
    },
  );
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void _handleNotificationTap(String? payload) {
  if (payload == null || payload.isEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(Routes.dashboard);
    });
    return;
  }
  try {
    json.decode(payload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(Routes.dashboard);
    });
  } catch (e) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(Routes.dashboard);
    });
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  usePathUrlStrategy();
  await FlutterFlowTheme.initialize();
  await dotenv.load(fileName: '.env');
  AppEnvironment.setup();
  await SharedPreference.init();
  await Hive.initFlutter();
  await Hive.openBox('fcmBox');

  if (kIsWeb) {
    runApp(const MyWebApp());
  } else {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebasemessageBackgroundHandler);
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    await _requestFCMPermission();
    await _setupLocalNotifications();
    await _requestNotificationPermission();
    FirebaseMessaging.instance.getToken().then((value) {
      SharedPreference.setFcmToken(value.toString());
      print("line 131 fcm $value");
    });
    SharedPreference.deletePhone();
    runApp(MyApp(initialMessage: initialMessage));
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

  @override
  void initState() {
    super.initState();

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
        debugPrint("Notification setup error: $e");
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
                icon: '@mipmap/launcher_icon',
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

  void setThemeMode(ThemeMode mode) => setState(() {
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

  void setThemeMode(ThemeMode mode) => setState(() {
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
