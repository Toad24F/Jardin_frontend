import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_screen.dart';
import 'add_habit_screen.dart';
import '../services/auth_service.dart';
import '../models/habito.dart'; // Importar el modelo de Hábito
import '../providers/habitos_provider.dart'; // Importar el nuevo provider de hábitos

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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Widget para construir un ítem del menú lateral (se mantiene igual)
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

  // Nuevo Widget para dibujar la maceta (Habito como botón)
  Widget _buildHabitMata(BuildContext context, Habito habito) {
    // La etapa de la mata debe estar entre 1 y 15 para corresponder a las imágenes
    final int etapa = habito.etapaMata.clamp(1, 15);
    final String imagePath = 'assets/$etapa.png';

    return GestureDetector(
      onTap: () {
        // TODO: Navegar a la pantalla del calendario/registro diario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hábito: ${habito.nombreHabito}. Etapa: $etapa'), backgroundColor: primaryColor),
        );
      },
      child: Column(
        children: [
          // Usamos Image.asset para cargar las imágenes de las matas
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
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);

    // 1. Observar el estado de los hábitos
    final habitosAsyncValue = ref.watch(habitosProvider);

    final TextStyle homeTitleStyle = appTitleStyle.copyWith(fontSize: 24, color: primaryColor);

    void navigateToAddHabit() {
      // Al volver de esta pantalla, queremos que se recarguen los hábitos.
      // Usamos .then() para invalidar el provider después de que la ruta se cierre.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AddHabitScreen()),
      ).then((_) {
        // 2. Invalidar el provider para forzar la recarga de los hábitos al volver
        ref.invalidate(habitosProvider);
      });
    }

    void logout() async {
      await authService.saveToken('');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
            (Route<dynamic> route) => false,
      );
    }

    return Scaffold(
      backgroundColor: lightBackgroundColor,
      // ... (AppBar y Drawer se mantienen, con navigateToAddHabit en los onTap) ...
      appBar: AppBar(
        title: Text('Jardín de Hábitos', style: homeTitleStyle),
        backgroundColor: lightBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor, size: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: navigateToAddHabit, // LLAMA A LA FUNCIÓN DE NAVEGACIÓN
          ),
          const SizedBox(width: 10),
        ],
      ),

      drawer: Drawer(
        child: Container(
          color: primaryColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // Área de información del usuario (Header)
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

              // Opciones de Navegación
              _buildDrawerItem(icon: Icons.home, title: 'Inicio', onTap: () => Navigator.pop(context)),
              _buildDrawerItem(icon: Icons.add_circle_outline, title: 'Registrar Hábito', onTap: () {
                Navigator.pop(context); // Cerrar Drawer
                navigateToAddHabit(); // LLAMA A LA FUNCIÓN DE NAVEGACIÓN
              }),

              const SizedBox(height: 250),

              // Opciones de Configuración y Sesión
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
              // 3. Estado de Carga (Loading)
              loading: () => const Center(child: CircularProgressIndicator()),

              // 4. Estado de Error
              error: (e, s) {
                // Si el error es 401 Unauthorized, forzamos el logout.
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
                      // Botón para reintentar la carga
                      ElevatedButton(
                        onPressed: () => ref.invalidate(habitosProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              },

              // 5. Estado de Datos (Data)
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

                // Muestra el GridView con las macetas
                return GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(40),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 40, // Reducido un poco para espacio
                    mainAxisSpacing: 40,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: habitos.length,
                  itemBuilder: (context, index) {
                    final habito = habitos[index];
                    return _buildHabitMata(context, habito);
                  },
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