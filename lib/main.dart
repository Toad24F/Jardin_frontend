import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart'; // Importa tu pantalla
import 'services/auth_service.dart'; // Importa tus servicios

void main() async {
  // 1. Asegura que Flutter esté inicializado antes de llamar a funciones nativas
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializamos SharedPreferences de forma síncrona antes de runApp
  final prefs = await SharedPreferences.getInstance();

  runApp(
    // ProviderScope es necesario para usar Riverpod
    ProviderScope(
      // 3. Sobreescribimos el Provider de SharedPreferences con la instancia síncrona
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // Color de fondo para que sea consistente
  static const Color backgroundColor = Color(0xFFEFE8DE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nota: El sharedPreferencesProvider ya no es un FutureProvider, sino un Provider simple
    // que fue sobreescrito síncronamente en main. Por lo tanto, no necesitamos .when() aquí.

    // Si la inicialización en main() fallara, la app ni siquiera llegaría aquí.

    return MaterialApp(
      title: 'Jardín de Hábitos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Tema general para la app
        primarySwatch: Colors.brown,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: backgroundColor,
      ),
      // Navegamos directamente a la pantalla de Auth, que es la primera vista
      home: const AuthScreen(),
    );
  }
}