// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unigo/model/user.dart';
import 'package:unigo/shared/animated_route.dart';
import 'package:unigo/shared/db_helper.dart';
import 'package:unigo/shared/myconfig.dart';
import 'package:unigo/view/mainscreen.dart';
import 'package:unigo/view/messagescreen.dart';
import 'package:unigo/view/splashscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  log("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await DBHelper.instance.database; // Ensures db and table created
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());

  // App opened from terminated state
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    log("NAVIGATE FROM TERMINATED");
    _handleNavigation(initialMessage.data);
  }

  // App opened from background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    Map data = message.data;
    log("FROM BACKGROUND, data: $message");
    _handleNavigation(message.data);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Unigo',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber.shade900,
          primary: Colors.amber.shade900,
          secondary: Colors.purple.shade600,
          surface: Colors.white,
          background: Colors.grey.shade100,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.amber.shade900,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          labelStyle: TextStyle(color: Colors.purple.shade600),
          prefixIconColor: Colors.amber.shade900,
        ),
        dividerColor: Colors.amber.shade200,
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Replace with your splash screen
    );
  }
}

Future<void> _backgroundHandler(RemoteMessage message) async {
  // Handle background message
}

void _handleNavigation(Map<String, dynamic> data) async {
  User user = await loadUserCredentials();
  if (data['screen'] == 'messagescreen') {
    navigatorKey.currentState?.push(
      AnimatedRoute.slideFromRight(MessageScreen(user: user)),
    );
  }
  if (data['screen'] == 'mainscreen') {
    navigatorKey.currentState?.push(
      AnimatedRoute.slideFromRight(MainScreen(user: user)),
    );
  }
}

Future<User> loadUserCredentials() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String email = prefs.getString('email') ?? '';
  String password = prefs.getString('pass') ?? '';
  bool remember = prefs.getBool('remember') ?? false;
  User user = User(
    userId: "0",
    userName: "Guest",
    userEmail: "",
    userPhone: "",
    userUniversity: "",
    userAddress: "",
    userPassword: "",
  );

  if (remember && email.isNotEmpty && password.isNotEmpty) {

    try {
      final response = await http.post(
        Uri.parse("${MyConfig.myurl}/unigo/php/login_user.php"),
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        var jsondata = json.decode(response.body);
        if (jsondata['status'] == 'success') {
          user = User.fromJson(jsondata['data'][0]);
        }
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }
  }
  return user;
}