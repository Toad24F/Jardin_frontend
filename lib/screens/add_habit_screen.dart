import 'package:Jardin_de_los_habitos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

// Se eliminan las constantes de color fijas y se reemplazan por referencias al tema.

// Colores y Estilos para consistencia
// Ahora son funciones que toman el contexto para obtener los colores dinámicos
TextStyle getAppBarTitleStyle(BuildContext context) {
  return TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.primary,
  );
}

TextStyle getLabelStyle(BuildContext context) {
  return TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onBackground,
  );
}

class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  int _dailyFrequency = 1; // Frecuencia por defecto
  bool _isLoading = false;

  // Manejador para guardar el hábito
  void _saveHabit() async {
    if (!_formKey.currentState!.validate()) {
      return; // Si la validación falla, sale
    }

    // Si la validación es exitosa, procede al POST
    final authService = ref.read(authServiceProvider);

    setState(() => _isLoading = true);

    try {
      await authService.createHabit(
        nombreHabito: _nameController.text,
        frecuenciaDiaria: _dailyFrequency,
        notas: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Éxito: Muestra un mensaje y regresa a la pantalla principal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hábito creado con éxito.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Regresar a HomeScreen
      }

    } catch (e) {
      // Error: Muestra el mensaje de error de la API
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear hábito: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onBackground = theme.colorScheme.onBackground;
    final cardColor = theme.colorScheme.surface; // Color de fondo de los campos

    final TextStyle appBarTitleStyle = getAppBarTitleStyle(context);
    final TextStyle labelStyle = getLabelStyle(context);
    final TextStyle descriptionTextStyle = TextStyle(
      fontSize: 16,
      color: onBackground.withOpacity(0.7),
    );


    return Scaffold(
      // Ya no tiene backgroundColor fijo, usa theme.scaffoldBackgroundColor
      appBar: AppBar(
        // Ya no tiene backgroundColor fijo, usa theme.appBarTheme
        elevation: 0,
        title: Text('Añade tu hábito', style: appBarTitleStyle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- 1. Nombre del Hábito ---
              TextFormField(
                controller: _nameController,
                style: TextStyle(fontSize: 22, color: onBackground), // Color de texto dinámico
                decoration: InputDecoration(
                  labelText: 'Nombre de tu hábito ...',
                  labelStyle: labelStyle.copyWith(color: primaryColor.withOpacity(0.7)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.never, // Mantiene el placeholder
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre del hábito es obligatorio.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // --- 2. Frecuencia Diaria ---
              Text('¿Cuantas veces es normal para tu hacerlo?', style: labelStyle),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Veces al día:',
                      style: descriptionTextStyle,
                    ),
                  ),
                  // Control de Número (Spinner)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Text(
                          '$_dailyFrequency',
                          style: TextStyle(
                            fontSize: 18,
                            color: onBackground, // Color de texto dinámico
                          ),
                        ),
                        Column(
                          children: [
                            SizedBox(
                              height: 30,
                              child: IconButton(
                                icon: Icon(Icons.arrow_drop_up, size: 20, color: primaryColor), // Color del ícono primario
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    _dailyFrequency++;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              height: 30,
                              child: IconButton(
                                icon: Icon(Icons.arrow_drop_down, size: 20, color: primaryColor), // Color del ícono primario
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    if (_dailyFrequency > 1) {
                                      _dailyFrequency--;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // --- 3. Notas (Motivo) ---
              Text('¿Por que es importante para ti registrar este mal hábito?', style: labelStyle),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cardColor, // Fondo del área de texto dinámico
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.5)),
                ),
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 5,
                  style: TextStyle(color: onBackground), // Color de texto dinámico
                  decoration: InputDecoration(
                    hintText: 'Ingrese aquí el porqué...',
                    hintStyle: TextStyle(color: onBackground.withOpacity(0.5)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // --- Botón Guardar ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveHabit,
                  // Los colores del botón ya se heredan correctamente de theme.elevatedButtonTheme
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}