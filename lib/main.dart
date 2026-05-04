import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wejoy/screens/activitie_page.dart';
import 'package:wejoy/screens/service/admin_api_service.dart';
import 'package:wejoy/screens/splash_screen.dart';
import 'package:wejoy/screens/login_page.dart';
import 'package:wejoy/screens/home_page.dart';
import 'package:wejoy/screens/admin/admin_shell.dart';
import 'package:wejoy/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger le thème sauvegardé avant de lancer l'app
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminApiService()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'WeJoy',
      debugShowCheckedModeBanner: false,

      // Thème clair dynamique
      theme: tp.lightTheme.copyWith(
        textTheme: tp.lightTheme.textTheme.apply(fontFamily: 'Roboto'),
      ),

      // Thème sombre dynamique
      darkTheme: tp.darkTheme.copyWith(
        textTheme: tp.darkTheme.textTheme.apply(fontFamily: 'Roboto'),
      ),

      // Suit le choix de l'utilisateur (clair ou sombre)
      themeMode: tp.themeMode,

      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/activity-detail': (_) =>
            const ActivityDetailPage(activityId: ''),
        '/admin': (_) => const AdminShell(),
      },
    );
  }
}