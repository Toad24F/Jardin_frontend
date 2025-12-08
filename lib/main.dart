import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

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

// --- Definición de Colores de la Paleta ---
// Colores principales de tu tema (basados en los archivos existentes)
const Color primaryColor = Color(0xFF6C4B4B); // Marrón/Rojizo oscuro
const Color accentGreen = Color(0xFF7D9C68);  // Verde de acento
const Color lightBackgroundColor = Color(0xFFDBCFB9); // Fondo claro (Crema)
const Color darkPrimaryColor = Color(0xFFDBCFB9); // Usamos el crema como acento en el modo oscuro
const Color darkBackgroundColor = Color(0xFF333333); // Fondo oscuro (Gris oscuro)
const Color darkCardColor = Color(0xFF424242); // Color de tarjetas/elementos en modo oscuro

// --- Definición de Temas ---
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColor,
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    secondary: accentGreen,
    background: lightBackgroundColor, // Color de fondo principal
    surface: Colors.white,           // Color de tarjetas y superficies
    onPrimary: Colors.white,
    onBackground: Colors.black87,
  ),
  scaffoldBackgroundColor: lightBackgroundColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: lightBackgroundColor,
    elevation: 0,
    iconTheme: IconThemeData(color: primaryColor),
    titleTextStyle: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  // Establece el color de los botones elevados
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: darkPrimaryColor, // El color primario en modo oscuro
  colorScheme: ColorScheme.dark(
    primary: darkPrimaryColor,
    secondary: accentGreen,
    background: darkBackgroundColor,
    surface: darkCardColor,
    onPrimary: Colors.black,
    onBackground: Colors.white70,
  ),
  scaffoldBackgroundColor: darkBackgroundColor,
  appBarTheme: AppBarTheme(
    backgroundColor: darkBackgroundColor,
    elevation: 0,
    iconTheme: const IconThemeData(color: darkPrimaryColor),
    titleTextStyle: TextStyle(color: darkPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkPrimaryColor,
      foregroundColor: Colors.black, // Texto oscuro en botón claro
    ),
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
// -------------------------

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final token = authService.getToken();

    final Widget initialScreen = (token != null && token.isNotEmpty)
        ? const HomeScreen() // Si hay token, va a Home
        : const AuthScreen(); // Si no hay token, va a Login/Register

    return MaterialApp(
      title: 'Jardín de Hábitos',
      debugShowCheckedModeBanner: false,

      // --- CONFIGURACIÓN DE TEMA AUTOMÁTICA ---
      theme: lightTheme,           // Tema usado por defecto (Modo Claro)
      darkTheme: darkTheme,         // Tema usado cuando el sistema está en Modo Oscuro
      themeMode: ThemeMode.system, // Usa la configuración de brillo del sistema operativo

      // Navegamos a la pantalla inicial determinada por el estado de autenticación
      home: initialScreen,
    );
  }
}