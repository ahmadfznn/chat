import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chat/firebase_options.dart';
import 'package:chat/features/auth/presentation/pages/auth.dart';
import 'package:chat/core/widgets/layout.dart';
import 'package:chat/core/utils/startup.dart';
import 'package:chat/services/status_service.dart';
import 'controllers/theme_controller.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  await FirebaseMessaging.instance
      .requestPermission(alert: true, badge: true, sound: true);
  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void showNotification(RemoteMessage message) {
  const androidDetails = AndroidNotificationDetails('1', 'chat',
      importance: Importance.high, priority: Priority.high, playSound: true);
  const platformDetails = NotificationDetails(android: androidDetails);
  flutterLocalNotificationsPlugin.show(0, message.notification?.title,
      message.notification?.body, platformDetails);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Received background message: ${message.notification?.title}");
}

Future<void> initializeFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('Firebase initialized');
  }
  await FirebaseAppCheck.instance
      .activate(androidProvider: AndroidProvider.debug);
  await initializeNotifications();
}

Future<bool> checkInternetConnection() async {
  final result = await Connectivity().checkConnectivity();
  return result != ConnectivityResult.none;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeFirebase();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen(showNotification);

  Get.put(ThemeController());
  runApp(const MainApp());
}

const Color primaryBlue = Color(0xFF3B82F6);
const Color deepBlue = Color(0xFF1E3A8A);
const Color softWhite = Color(0xFFF9FAFB);
const Color navSelected = primaryBlue;
const Color navUnselected = Color(0xFF9CA3AF);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() => GetMaterialApp(
          title: "Chat",
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode.value,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: softWhite,
            primaryColor: primaryBlue,
            colorScheme: const ColorScheme.light(
                primary: primaryBlue,
                secondary: deepBlue,
                surface: Colors.white,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: Colors.black),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              titleTextStyle: TextStyle(
                  color: deepBlue, fontSize: 20, fontWeight: FontWeight.bold),
              iconTheme: IconThemeData(color: primaryBlue),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: navSelected,
              unselectedItemColor: navUnselected,
              showSelectedLabels: true,
              showUnselectedLabels: true,
            ),
            textTheme:
                GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          ),
          darkTheme: ThemeData.dark().copyWith(
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          ),
          home: const MainAppScreen(),
        ));
  }
}

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});
  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen>
    with WidgetsBindingObserver {
  final StatusService _statusService = StatusService();
  late final StreamSubscription _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {}
    });

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      isConnected
          ? _statusService.setUserOnline()
          : _statusService.setUserOffline();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ([
      AppLifecycleState.paused,
      AppLifecycleState.detached,
      AppLifecycleState.inactive,
      AppLifecycleState.hidden
    ].contains(state)) {
      _statusService.setUserOffline();
    } else if (state == AppLifecycleState.resumed) {
      _statusService.setUserOnline();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: checkSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final user = snapshot.data?["user"];
          return user != null ? Layout(user: user) : const Auth(page: 0);
        }
        return const Startup();
      },
    );
  }
}

Future<Map<String, dynamic>> checkSession() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    final res = await FirebaseFirestore.instance
        .collection("users")
        .where("email", isEqualTo: currentUser.email)
        .get();
    if (res.docs.isNotEmpty) {
      final result = res.docs.first;
      return {
        "user": {"id": result.id, ...result.data()}
      };
    }
  }
  return {"user": null};
}
