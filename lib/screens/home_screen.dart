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

// Se eliminan las constantes de color fijas y se reemplazan por referencias al tema.

// Se mantiene el estilo de texto como una función que acepta el tema (o contexto)
// para poder acceder a los colores dinámicamente.
TextStyle getAppTitleStyle(BuildContext context) {
  final primaryColor = Theme.of(context).colorScheme.primary;
  return TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );
}

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
  // Nuevo estado para evitar recargas automáticas infinitas en caso de error persistente.
  bool _hasAttemptedRefetchAfterLoginError = false;

  // Inicialización de posiciones
  @override
  void initState() {
    super.initState();
    // La inicialización ahora se hace en build/whenData para asegurar
    // que tanto el habitosProvider como los servicios locales estén listos.
  }

  // Distribuye las macetas en una cuadrícula inicial si *no* hay posiciones guardadas
  void _initializePositions(
      List<Habito> habitos,
      LocalHabitPositionService localStorageService,
      ) {
    if (_isInitialized || habitos.isEmpty) return;

    // 1. Intentar cargar posiciones guardadas localmente
    final savedPositions = localStorageService.loadPositions();
    final Map<String, Offset> initialPositions = {};

    // 2. Usar posiciones guardadas o calcular posiciones por defecto
    if (savedPositions.isNotEmpty) {
      for (var habit in habitos) {
        initialPositions[habit.id] =
            savedPositions[habit.id] ?? _getDefaultPosition(habitos, habit.id);
      }
    } else {
      // Generar posiciones por defecto si es la primera carga absoluta o si no hay posiciones
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

    return Offset(startX + col * stepX, startY + row * stepY);
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
    required BuildContext context, // Necesario para Theme
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    // Eliminamos el color fijo, siempre será blanco o el color de acento.
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    // Color de texto e ícono dinámico para el Drawer (blanco en claro, acento en oscuro)
    final itemColor = isDarkMode ? theme.colorScheme.primary : primaryColor;

    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // Widget de la Maceta Draggable
  Widget _buildHabitMata(BuildContext context, Habito habito) {
    // Leemos el color primario del tema para el texto
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 1. Obtener la posición actual
    Offset position =
        _habitPositions[habito.id] ??
            _getDefaultPosition(ref.watch(habitosProvider).value ?? [], habito.id);

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
          // Al soltar la maceta, guardamos la nueva posición en SharedPreferences.
          final localStorageService = ref.read(localStorageServiceProvider);
          localStorageService.savePositions(_habitPositions).catchError((
              error,
              ) {
            _showError(error);
          });

          print('Posición final guardada localmente: ${habito.nombreHabito}');
        },
        // Al tocar la maceta (para ir a la vista de calendario)
        onTap: () {
          // 1. Invalidar el provider de registros *antes* de navegar
          ref.invalidate(
            currentHabitRegistrosProvider(habito.id),
          ); // <-- ESTO ES CLAVE

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CalendarScreen(habito: habito),
            ),
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
                return Icon(Icons.park, size: 100, color: primaryColor);
              },
            ),
            const SizedBox(height: 5),
            Text(
              habito.nombreHabito,
              textAlign: TextAlign.center,
              style: TextStyle(
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
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.read(authServiceProvider);
    final localStorageService = ref.read(
      localStorageServiceProvider,
    ); // Nuevo servicio

    // Colores dinámicos del tema
    final primaryColor = Theme.of(context).colorScheme.primary;
    final accentGreen = Theme.of(context).colorScheme.secondary;
    final onBackground = Theme.of(context).colorScheme.background;

    final String userName = authService.getUserName() ?? 'Usuario';
    final String userEmail = authService.getUserEmail() ?? 'Correo@gmail.com';
    final habitosAsyncValue = ref.watch(habitosProvider);

    // Estilo del título adaptado al tema
    final TextStyle homeTitleStyle = getAppTitleStyle(context).copyWith(
      fontSize: 24,
      color: primaryColor, // Usamos el color primario del tema
    );


    void navigateToAddHabit() {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const AddHabitScreen()))
          .then((_) {
        ref.invalidate(habitosProvider);
      });
    }

    void logout() async {
      await authService.saveToken('');

      // FIX: Al cerrar sesión, limpiamos el estado local de la posición.
      await localStorageService.savePositions({});

      // También limpiamos el estado local en el componente
      setState(() {
        _habitPositions = {};
        _isInitialized = false;
        _hasAttemptedRefetchAfterLoginError = false; // Resetear el control de recarga
      });

      // Aseguramos que el proveedor de hábitos se invalide y no mantenga los datos de la cuenta anterior.
      ref.invalidate(habitosProvider);

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
        // FIX: Limpiamos las posiciones guardadas localmente al detectar que la lista de hábitos está vacía
        localStorageService.savePositions({});
      }

      // Si la carga fue exitosa, podemos resetear el control de reintento.
      if (_hasAttemptedRefetchAfterLoginError) {
        // Se carga correctamente después del reintento automático.
        _hasAttemptedRefetchAfterLoginError = false;
      }
    });

    return Scaffold(
      // El color de fondo lo toma del theme.scaffoldBackgroundColor

      // --- AppBar (Adaptada al tema) ---
      appBar: AppBar(
        title: Text('Jardín de Hábitos', style: homeTitleStyle),
        // Los colores de AppBar se heredan de theme.appBarTheme
        iconTheme: IconThemeData(color: primaryColor, size: 30), // Aseguramos el color de los íconos (siempre primary)
        actions: [
          // Botones usan el color del IconTheme de AppBar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(habitosProvider),
            tooltip: 'Refrescar la lista de hábitos',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: navigateToAddHabit,
            tooltip: 'Añadir nuevo hábito',
          ),
          const SizedBox(width: 10),
        ],
      ),

      // --- Menú Lateral (Adaptado al tema) ---
      drawer: Drawer(
        child: Container(
          color: onBackground, // El Drawer siempre usa el color primario (primaryColor) como fondo.
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                // Fondo del header es el mismo que el Drawer
                decoration: BoxDecoration(color: onBackground),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                        'https://placehold.co/100x100/FFFFFF/000000?text=U',
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Usamos el nombre real (Texto siempre blanco)
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Usamos el correo real (Texto en gris suave)
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: primaryColor, // Color fijo que contrasta
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              _buildDrawerItem(
                context: context,
                icon: Icons.home,
                title: 'Inicio',
                onTap: () => Navigator.pop(context),
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.add_circle_outline,
                title: 'Registrar Hábito',
                onTap: () {
                  Navigator.pop(context);
                  navigateToAddHabit();
                },
              ),

              _buildDrawerItem(
                context: context,
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
              loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),

              error: (e, s) {
                final isTokenNotFoundError = e.toString().contains('Token JWT no encontrado');

                // FIX: Detectamos el error de carrera (token no cargado a tiempo)
                if (isTokenNotFoundError && !_hasAttemptedRefetchAfterLoginError) {
                  // Marcamos que hemos intentado el reintento automático para evitar bucles.
                  setState(() {
                    _hasAttemptedRefetchAfterLoginError = true;
                  });

                  // Reintentamos la carga de hábitos en el siguiente ciclo de construcción.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.invalidate(habitosProvider);
                  });

                  // Mostramos un indicador de carga mientras se reintenta automáticamente.
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                // Lógica de error original para 401
                if (e is DioException && e.response?.statusCode == 401) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => logout());
                  return Center(
                    child: Text(
                      "Sesión expirada. Redirigiendo...",
                      style: TextStyle(color: primaryColor),
                    ),
                  );
                }

                // Lógica de error para cualquier otro error
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error al cargar hábitos: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 10),
                      // Dejamos el botón "Reintentar" solo para errores no manejados automáticamente.
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
                        Text(
                          '¡Aún no tienes hábitos registrados!',
                          style: TextStyle(fontSize: 18, color: primaryColor),
                        ),
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
                    ...habitos
                        .map((habito) => _buildHabitMata(context, habito))
                        .toList(),
                  ],
                );
              },
            ),
          ),

          // Barra inferior (la tierra verde)
          Container(height: 80, width: double.infinity, color: accentGreen),
        ],
      ),
    );
  }
}