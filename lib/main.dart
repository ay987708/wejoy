import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wejoy/screens/activitie_page.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';
import 'package:wejoy/screens/splash_screen.dart';
import 'package:wejoy/screens/login_page.dart';
import 'package:wejoy/screens/home_page.dart';

import 'package:wejoy/screens/admin/admin_shell.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminApiService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeJoy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/activity-detail': (_) => const ActivityDetailPage(activityId: ''),
        '/admin': (_) => const AdminShell(),
      },
    );
  }
}