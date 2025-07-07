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

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(MaterialApp(
//       initialRoute: '/home',
//       routes: {
//         // '/' : (context) => Loading(),
//         '/home': (context) => HomePage(),
//         '/cpu': (context) => CpuScreen(),
//         // '/mobo': (context) => ,
//         // '/gpu': (context) => ,
//         // '/ram': (context) => ,
//         // '/': (context) => ,
//         // '/': (context) => ,
//       },
//   )
//   );
// }


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [Provider<AuthService>(create: (_) => AuthService()), ChangeNotifierProvider(create: (_) => ConfigurationProvider()),],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Configurator',
      theme: ThemeData(/* your theme */),
      home: const AuthWrapper(), // Auth handles login/home decision
      routes: {
        '/home': (context) => HomePage(),
        '/cpu': (context) => CpuScreen(),
        '/mobo': (context) => MoboScreen(),
        '/gpu': (context) => GpuScreen(),
        '/ram': (context) => RamScreen(),
        '/storage': (context) => StorageScreen(),
        '/psu': (context) => PsuScreen(),
        '/case': (context) => CaseScreen(),
        '/summary': (context) => SummaryScreen()
      },
    );
  }
}

