import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart'; // Importa tu pantalla
import 'screens/home_screen.dart'; // Importa la nueva pantalla principal
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
  static const Color backgroundColor = Color(0xFFDBCFB9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El AuthService ya está listo para ser usado porque SharedPreferences
    // se resolvió en main() y se inyectó de forma síncrona.
    final authService = ref.watch(authServiceProvider);

    // Obtenemos el token guardado (si existe)
    final token = authService.getToken();

    // Determinamos la pantalla de inicio
    final Widget initialScreen = (token != null && token.isNotEmpty)
        ? const HomeScreen() // Si hay token, va a Home
        : const AuthScreen(); // Si no hay token, va a Login/Register

    return MaterialApp(
      title: 'Jardín de Hábitos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Tema general para la app
        primarySwatch: Colors.brown,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: backgroundColor,
      ),
      // Navegamos a la pantalla inicial determinada por el estado de autenticación
      home: initialScreen,
    );
  }
}