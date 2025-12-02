import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_screen.dart';
import 'add_habit_screen.dart';
import '../services/auth_service.dart';
import '../models/habito.dart';
import '../providers/habitos_provider.dart';
import '../services/local_storage_service.dart';
import 'calendar_screen.dart'; // Importar nuevo servicio local

// Definición de colores principales
const Color primaryColor = Color(0xFF6C4B4B);
const Color lightBackgroundColor = Color(0xFFEFE8DE);
const Color accentGreen = Color(0xFF7D9C68);

// Para mantener la consistencia del título
final TextStyle appTitleStyle = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: primaryColor,
);

// Cambiamos a ConsumerStatefulWidget para manejar el estado de posición
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Mapa para almacenar la posición actual de cada maceta
  Map<String, Offset> _habitPositions = {};
  bool _isInitialized = false;

  // Inicialización de posiciones
  @override
  void initState() {
    super.initState();
    // La inicialización ahora se hace en build/whenData para asegurar
    // que tanto el habitosProvider como los servicios locales estén listos.
  }

  // Distribuye las macetas en una cuadrícula inicial si *no* hay posiciones guardadas
  void _initializePositions(List<Habito> habitos, LocalHabitPositionService localStorageService) {
    if (_isInitialized || habitos.isEmpty) return;

    // 1. Intentar cargar posiciones guardadas localmente
    final savedPositions = localStorageService.loadPositions();
    final Map<String, Offset> initialPositions = {};

    // 2. Usar posiciones guardadas o calcular posiciones por defecto
    if (savedPositions.isNotEmpty) {
      for (var habit in habitos) {
        initialPositions[habit.id] = savedPositions[habit.id] ?? _getDefaultPosition(habitos, habit.id);
      }
    } else {
      // Generar posiciones por defecto si es la primera carga absoluta
      _initializeDefaultPositions(habitos);
      // No salimos de aquí, ya que _initializeDefaultPositions llama a setState
      _isInitialized = true;
      return;
    }

    setState(() {
      _habitPositions = initialPositions;
      _isInitialized = true;
    });
  }

  // Calcula una posición inicial escalonada (fallback)
  Offset _getDefaultPosition(List<Habito> habitos, String habitId) {
    final index = habitos.indexWhere((h) => h.id == habitId);
    if (index == -1) return const Offset(30.0, 50.0);

    const double stepX = 150.0;
    const double stepY = 180.0;
    const double startX = 30.0;
    const double startY = 50.0;

    final int col = index % 2;
    final int row = index ~/ 2;

    return Offset(
      startX + col * stepX,
      startY + row * stepY,
    );
  }

  // Función interna para generar la distribución por defecto y actualizar el estado
  void _initializeDefaultPositions(List<Habito> habitos) {
    if (habitos.isEmpty) return;

    final Map<String, Offset> defaultPositions = {};
    for (var habit in habitos) {
      defaultPositions[habit.id] = _getDefaultPosition(habitos, habit.id);
    }

    setState(() {
      _habitPositions = defaultPositions;
      _isInitialized = true;
    });
  }

  // Función para construir un ítem del menú lateral
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // Widget de la Maceta Draggable
  Widget _buildHabitMata(BuildContext context, Habito habito) {
    // 1. Obtener la posición actual
    Offset position = _habitPositions[habito.id] ?? _getDefaultPosition(ref.watch(habitosProvider).value ?? [], habito.id);

    final int etapa = habito.etapaMata.clamp(1, 15);
    final String imagePath = 'assets/$etapa.png';

    // Usamos un Stack + Positioned para el posicionamiento absoluto
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // Actualiza la posición sumando el delta de arrastre
            final newPosition = Offset(
              position.dx + details.delta.dx,
              position.dy + details.delta.dy,
            );
            _habitPositions[habito.id] = newPosition;
          });
        },
        onPanEnd: (details) {
          // *** IMPLEMENTACIÓN PARA PERSISTENCIA LOCAL ***
          // Al soltar la maceta, guardamos la nueva posición en SharedPreferences.
          final localStorageService = ref.read(localStorageServiceProvider);
          localStorageService.savePositions(_habitPositions).catchError((error) {
            _showError(error);
          });

          print('Posición final guardada localmente: ${habito.nombreHabito}');
        },
        // Al tocar la maceta (para ir a la vista de calendario)
        onTap: () {
          // TODO: Navegar a la pantalla del calendario/registro diario
          Navigator.of(context).push(
            // Navegamos a CalendarScreen, pasando el objeto Habito
            MaterialPageRoute(builder: (context) => CalendarScreen(habito: habito)),
          );
        },
        child: Column(
          children: [
            Image.asset(
              imagePath,
              height: 120,
              width: 120,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si la imagen (1.png a 15.png) no se encuentra
                return const Icon(Icons.park, size: 100, color: primaryColor);
              },
            ),
            const SizedBox(height: 5),
            Text(
              habito.nombreHabito,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función de error simple
  void _showError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Error: ${error.toString()}',
            style: const TextStyle(color: Colors.white)
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);
    final localStorageService = ref.read(localStorageServiceProvider); // Nuevo servicio

    final habitosAsyncValue = ref.watch(habitosProvider);
    final TextStyle homeTitleStyle = appTitleStyle.copyWith(fontSize: 24, color: primaryColor);

    void navigateToAddHabit() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AddHabitScreen()),
      ).then((_) {
        ref.invalidate(habitosProvider);
      });
    }

    void logout() async {
      await authService.saveToken('');
      // Opcional: Limpiar posiciones locales al cerrar sesión
      await localStorageService.savePositions({});

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
            (Route<dynamic> route) => false,
      );
    }

    // Inicialización de posiciones al obtener los datos la primera vez
    habitosAsyncValue.whenData((habitos) {
      if (!_isInitialized && habitos.isNotEmpty) {
        _initializePositions(habitos, localStorageService);
      } else if (habitos.isEmpty && _habitPositions.isNotEmpty) {
        // Limpia posiciones si el usuario eliminó todos los hábitos
        _habitPositions = {};
        _isInitialized = false;
        localStorageService.savePositions({});
      }
    });


    return Scaffold(
      backgroundColor: lightBackgroundColor,

      // --- AppBar (Se mantiene igual) ---
      appBar: AppBar(
        title: Text('Jardín de Hábitos', style: homeTitleStyle),
        backgroundColor: lightBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor, size: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: navigateToAddHabit,
          ),
          const SizedBox(width: 10),
        ],
      ),

      // --- Menú Lateral (Se mantiene igual) ---
      drawer: Drawer(
        child: Container(
          color: primaryColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(color: primaryColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage('https://placehold.co/100x100/FFFFFF/000000?text=U'),
                    ),
                    SizedBox(height: 10),
                    Text('Usuario', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Correo@gmail.com', style: TextStyle(color: Color(0xFFC7B1A5), fontSize: 14)),
                  ],
                ),
              ),

              _buildDrawerItem(icon: Icons.home, title: 'Inicio', onTap: () => Navigator.pop(context)),
              _buildDrawerItem(icon: Icons.add_circle_outline, title: 'Registrar Hábito', onTap: () {
                Navigator.pop(context);
                navigateToAddHabit();
              }),

              const SizedBox(height: 250),

              _buildDrawerItem(icon: Icons.person, title: 'Usuario'),
              _buildDrawerItem(icon: Icons.settings, title: 'Ajustes'),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Cerrar sesión',
                onTap: logout,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // --- Cuerpo de la Pantalla (Manejo del estado de la API) ---
      body: Column(
        children: [
          Expanded(
            child: habitosAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),

              error: (e, s) {
                if (e is DioException && e.response?.statusCode == 401) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => logout());
                  return const Center(child: Text("Sesión expirada. Redirigiendo...", style: TextStyle(color: primaryColor)));
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error al cargar hábitos: $e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(habitosProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              },

              data: (habitos) {
                if (habitos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¡Aún no tienes hábitos registrados!', style: TextStyle(fontSize: 18, color: primaryColor)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: navigateToAddHabit,
                          icon: const Icon(Icons.add),
                          label: const Text('Crear primer hábito'),
                        ),
                      ],
                    ),
                  );
                }

                // Si la inicialización no ha terminado, mostramos las macetas
                // con las posiciones por defecto o guardadas
                return Stack(
                  children: [
                    ...habitos.map((habito) => _buildHabitMata(context, habito)).toList(),
                  ],
                );
              },
            ),
          ),

          // Barra inferior (la tierra verde)
          Container(
            height: 80,
            width: double.infinity,
            color: accentGreen,
          ),
        ],
      ),
    );
  }
}