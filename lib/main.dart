import 'package:flutter/material.dart';
import 'package:zavrsni/pages/auth_service.dart';
import 'package:zavrsni/pages/auth_wrapper.dart';
import 'package:zavrsni/pages/case_screen.dart';
import 'package:zavrsni/pages/cpu_screen.dart';
import 'package:zavrsni/pages/gpu_screen.dart';
import 'package:zavrsni/pages/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:zavrsni/pages/mobo_screen.dart';
import 'package:zavrsni/pages/psu_screen.dart';
import 'package:zavrsni/pages/ram_screen.dart';
import 'package:zavrsni/pages/storage_screen.dart';
import 'package:zavrsni/pages/summary_screen.dart';
import 'pages/configuration_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ConfigurationProvider()),
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
      title: 'Build My PC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green.shade900,
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade900,
          centerTitle: true,
          elevation: 4,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => HomePage(),
        '/cpu': (context) => CpuScreen(),
        '/mobo': (context) => MoboScreen(),
        '/gpu': (context) => GpuScreen(),
        '/ram': (context) => RamScreen(),
        '/storage': (context) => StorageScreen(),
        '/psu': (context) => PsuScreen(),
        '/case': (context) => CaseScreen(),
        '/summary': (context) => SummaryScreen(),
        '/saved_configurations': (context) => SummaryScreen(),
      },
    );
  }
}

