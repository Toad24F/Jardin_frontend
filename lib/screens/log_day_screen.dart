import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Se eliminan las constantes de color fijo.
// inputFillColor se leerá desde theme.colorScheme.surface (cardColor)

class LogDayScreen extends ConsumerStatefulWidget {
  final String habitoId;
  const LogDayScreen({super.key, required this.habitoId});

  @override
  ConsumerState<LogDayScreen> createState() => _LogDayScreenState();
}

class _LogDayScreenState extends ConsumerState<LogDayScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sentimientoController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();

  // Opciones de Dificultad: 1 (Muy fácil) a 5 (Muy difícil)
  final List<Map<String, dynamic>> _dificultadOptions = const [
    {'value': 1, 'label': '1 (Muy fácil)'},
    {'value': 2, 'label': '2 (Fácil)'},
    {'value': 3, 'label': '3 (Normal)'},
    {'value': 4, 'label': '4 (Difícil)'},
    {'value': 5, 'label': '5 (Muy difícil)'},
  ];

  int _vecesRealizadas = 0; // Campo para cuántas veces lo hiciste
  int? _dificultad = 3; // Valor inicial por defecto (Normal)
  bool _isLoading = false;

  // Manejador para el POST del registro
  void _saveLog() async {
    if (!_formKey.currentState!.validate() || _dificultad == null) {
      return;
    }

    final authService = ref.read(authServiceProvider);

    setState(() => _isLoading = true);

    try {
      await authService.logHabitDay(
        habitId: widget.habitoId,
        vecesRealizadas: _vecesRealizadas,
        dificultad: _dificultad!,
        sentimiento: _sentimientoController.text.isEmpty ? null : _sentimientoController.text,
        motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Día registrado con éxito.'), backgroundColor: Colors.green),
        );
        // Regresar a CalendarScreen
        Navigator.pop(context, true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Widget para el control de veces realizadas (spinner)
  Widget _buildFrequencyControl(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onBackground = Theme.of(context).colorScheme.onBackground;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text(
                '$_vecesRealizadas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: onBackground, // Color de texto dinámico
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    height: 25,
                    child: IconButton(
                      icon: Icon(Icons.arrow_drop_up, size: 25, color: primaryColor),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _vecesRealizadas++;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    height: 25,
                    child: IconButton(
                      icon: Icon(Icons.arrow_drop_down, size: 25, color: primaryColor),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          if (_vecesRealizadas > 0) {
                            _vecesRealizadas--;
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
    );
  }

  // Estilo común para los títulos de sección
  TextStyle _sectionTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onBackground, // Texto en el fondo (negro o blanco)
    );
  }

  // Estilo común para los campos de texto
  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;
    final onBackground = Theme.of(context).colorScheme.onBackground;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: onBackground.withOpacity(0.5)),
      fillColor: cardColor, // Color de superficie/tarjeta (blanco o gris oscuro)
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).colorScheme.surface;
    final onBackground = Theme.of(context).colorScheme.onBackground;

    return Scaffold(
      // Ya no tiene backgroundColor fijo, usa theme.scaffoldBackgroundColor
      appBar: AppBar(
        // Los colores se heredan del theme.appBarTheme
        elevation: 0,
        title: Text('Registra tu día', style: _sectionTitleStyle(context).copyWith(fontSize: 20, color: primaryColor)),
        centerTitle: true,
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
              // --- 1. ¿Cuántas veces lo hiciste? ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('¿Cuántas veces lo hiciste?', style: _sectionTitleStyle(context)),
                  _buildFrequencyControl(context),
                ],
              ),
              const SizedBox(height: 30),

              // --- 2. ¿Cómo te sentiste al hacerlo? (Sentimiento) ---
              Text('¿Cómo te sentiste al hacerlo?', style: _sectionTitleStyle(context)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sentimientoController,
                maxLines: 3,
                style: TextStyle(color: onBackground), // Color de texto dinámico
                decoration: _inputDecoration(context, 'Escribe como te sentiste aquí...'),
                validator: (value) {
                  // No requiere validación porque es opcional
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // --- 3. ¿Por qué lo hiciste? (Motivo) ---
              Text('¿Por qué lo hiciste?', style: _sectionTitleStyle(context)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _motivoController,
                maxLines: 3,
                style: TextStyle(color: onBackground), // Color de texto dinámico
                decoration: _inputDecoration(context, 'Escribe por qué lo hiciste aquí...'),
                validator: (value) {
                  // No requiere validación porque es opcional
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // --- 4. ¿Qué tan difícil fue hoy? (Dificultad) ---
              Text('¿Qué tan difícil fue hoy?', style: _sectionTitleStyle(context)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: cardColor, // Fondo del Dropdown dinámico
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryColor.withOpacity(0.5)),
                ),
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(border: InputBorder.none),
                  value: _dificultad,
                  hint: Text('Selecciona la dificultad', style: TextStyle(color: onBackground.withOpacity(0.5))),
                  style: TextStyle(color: onBackground), // Color del texto seleccionado
                  dropdownColor: cardColor, // Color del menú desplegable
                  items: _dificultadOptions.map((option) {
                    return DropdownMenuItem<int>(
                      value: option['value'],
                      child: Text(option['label'], style: TextStyle(color: onBackground)), // Color de las opciones
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    setState(() {
                      _dificultad = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona un nivel de dificultad.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 60),

              // --- Botón Guardar ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLog,
                  // Los colores del botón se heredan de theme.elevatedButtonTheme
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