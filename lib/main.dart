import 'dart:async';

import 'package:chat/etc/startup.dart';
import 'package:chat/pages/auth/auth.dart';
import 'package:chat/firebase_options.dart';
import 'package:chat/layout.dart';
import 'package:chat/services/socket_service.dart';
import 'package:chat/services/status_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'controllers/theme_controller.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void initializeNotifications() {
  requestPermission();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void showNotification(RemoteMessage message) {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    '1',
    'chat',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  flutterLocalNotificationsPlugin.show(0, message.notification?.title,
      message.notification?.body, platformChannelSpecifics);
}

Future<bool> checkInternetConnection() async {
  final List<ConnectivityResult> connectivityResult =
      await (Connectivity().checkConnectivity());
  if (connectivityResult.contains(ConnectivityResult.mobile)) {
    return true;
  } else {
    return false;
  }
}

void requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print("⚠️ Izin notifikasi ditolak oleh pengguna.");
  } else if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ Izin notifikasi diberikan.");
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print("⚠️ Izin notifikasi diberikan secara provisional.");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeFirebase();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // if (routeController.currentRoute.value != "/detailChat") {
    showNotification(message);
    // }
  });

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  Get.put(ThemeController());
  runApp(const MainApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ignore: avoid_print
  print("Pesan diterima di background: ${message.notification?.title}");
}

Future<void> initializeFirebase() async {
  var initialize = false;

  try {
    // ignore: avoid_print
    if (Firebase.apps.isEmpty && !initialize) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).whenComplete(() {
        // ignore: avoid_print
        print('Firebase initialized successfully');
        initialize = true;
      });
    } else {
      // ignore: avoid_print
      print('Firebase already initialized');
      initialize = true;
    }

    initializeNotifications();
  } catch (e, stacktrace) {
    // ignore: avoid_print
    print('Failed to initialize Firebase: $e');
    // ignore: avoid_print
    print(stacktrace);
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    return Obx(() => GetMaterialApp(
      title: "Chat",
      debugShowCheckedModeBanner: false,
      themeMode: themeController.themeMode.value,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
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
  // ignore: library_private_types_in_public_api
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen>
    with WidgetsBindingObserver {
  final StatusService _statusService = StatusService();
  late StreamSubscription _connectivitySubscription;
  bool _isConnected = true;
  late SocketService socketService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // _statusService.setUserOnline();

        // socketService = SocketService(user.uid);

        // socketService.socket.on("update-user-status", (data) {
        //   setState(() {
        //     // ignore: avoid_print
        //     print(List<String>.from(data));
        //   });
        // });
      }
    });

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      // ignore: unrelated_type_equality_checks
      bool isConnected = ConnectivityResult.none != result;
      if (_isConnected != isConnected) {
        _isConnected = isConnected;
        if (!isConnected) {
          _statusService.setUserOffline();
        } else {
          _statusService.setUserOnline();
        }
      }
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      _statusService.setUserOffline();
    } else if (state == AppLifecycleState.resumed) {
      _statusService.setUserOnline();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: checkSession(),
      builder: (context, data) {
        if (data.connectionState == ConnectionState.done) {
          if (data.data!['user'] != null) {
            return Layout(
              user: data.data!['user'],
            );
          } else {
            return Auth(page: 0);
          }
        } else {
          return const Startup();
        }
      },
    );
  }
}

Future<Map<String, dynamic>> checkSession() async {
  try {
    final data = FirebaseAuth.instance.currentUser;
    if (data != null) {
      final res = await FirebaseFirestore.instance
          .collection("users")
          .where("email", isEqualTo: data.email)
          .get();
      if (res.docs.isNotEmpty) {
        final result = res.docs[0];
        return {
          "user": {"id": result.id, ...result.data()}
        };
      } else {
        return {"user": null};
      }
    } else {
      return {"user": null};
    }
  } catch (e) {
    // ignore: avoid_print
    print('Error checking token: $e');
    return {"user": null};
  }
}
