import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

// Colores y Estilos para consistencia
const Color primaryTextColor = Color(0xFF6C4B4B); // Rojizo oscuro
const Color backgroundColor = Color(0xFFEFE8DE); // Fondo principal claro
const Color buttonColor = Color(0xFF6C4B4B); // Usaremos el primaryTextColor para el botón de Guardar
const Color buttonTextColor = Colors.white;

final TextStyle appBarTitleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold,
  color: primaryTextColor,
);

final TextStyle labelStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text('Añade tu hábito', style: appBarTitleStyle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryTextColor),
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
                style: const TextStyle(fontSize: 22, color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Nombre de tu hábito ...',
                  labelStyle: labelStyle.copyWith(color: primaryTextColor.withOpacity(0.7)),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryTextColor, width: 2),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryTextColor, width: 2),
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
                      border: Border.all(color: primaryTextColor),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Text('$_dailyFrequency', style: const TextStyle(fontSize: 18)),
                        Column(
                          children: [
                            SizedBox(
                              height: 30,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_drop_up, size: 20),
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
                                icon: const Icon(Icons.arrow_drop_down, size: 20),
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
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryTextColor.withOpacity(0.5)),
                ),
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Ingrese aquí el porqué...',
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: buttonTextColor)
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