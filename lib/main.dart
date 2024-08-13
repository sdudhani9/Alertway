import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:suraksha3/auth_service.dart';
import 'package:suraksha3/basicpage.dart';
import 'package:suraksha3/getstrt.dart';
import 'package:suraksha3/incident_report_form_screen.dart';
import 'package:suraksha3/incident_service.dart';
import 'package:suraksha3/locationpref_page.dart';
import 'package:suraksha3/login_screen.dart';
import 'package:suraksha3/signup_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyC-eJb1xQziXoZfgO1uPtw0Qsxf0RWaA84",
      appId: "1:1064898759252:android:b7e1df97e1efc96f31bbc1",
      messagingSenderId: "1064898759252",
      storageBucket: "crime-reporting-app-62193.appspot.com",
      projectId: "crime-reporting-app-62193",
    ),
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(SaarthiApp());
}

class SaarthiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => IncidentService()),
      ],
      child: MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => OnboardingScreen(),
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignUpScreen(),
          '/incidentReportForm': (context) => IncidentReportFormScreen(),
          '/MyHomePage': (context) => MyHomePage(),
          '/locationPreference': (context) => LocationprefPage(),
          '/resetPassword': (context) => ResetPasswordScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
