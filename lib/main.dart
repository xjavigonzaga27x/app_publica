import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_p_publica/screens/home_screen.dart';
import 'package:app_p_publica/firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase con las opciones generadas
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ejecutar la aplicación
  runApp(const PredicacionApp());
}

class PredicacionApp extends StatelessWidget {
  const PredicacionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Predicación',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true, // Usar Material Design 3
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      // Configuración para admitir español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // Español
      ],
      // Página inicial
      home: const HomeScreen(),
    );
  }
}
