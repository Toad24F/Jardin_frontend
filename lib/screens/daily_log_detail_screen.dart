import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/registro_dia.dart';
import 'package:intl/intl.dart'; // Importar intl para formatear la fecha

// Mantenemos solo el mapeo de dificultad y los colores semánticos (estado)
// Mapeo de Dificultad para mostrar el texto en lugar del número
const Map<int, String> dificultadMap = {
  1: 'Muy fácil',
  2: 'Fácil',
  3: 'Normal',
  4: 'Difícil',
  5: 'Muy difícil',
};

class DailyLogDetailScreen extends ConsumerWidget {
  final RegistroDia registro;

  // Recibimos el registro completo para mostrar sus datos
  const DailyLogDetailScreen({super.key, required this.registro});

  // Widget de utilidad para mostrar campos de texto (solo lectura)
  Widget _buildReadOnlyField(BuildContext context, String label, String content) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.colorScheme.surface;
    final onBackground = theme.colorScheme.onBackground;

    final TextStyle sectionTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: onBackground,
    );
    final TextStyle contentTextStyle = TextStyle(
      fontSize: 16,
      color: onBackground,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: sectionTitleStyle),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor, // Fondo dinámico
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primaryColor.withOpacity(0.5)),
          ),
          child: Text(
            content,
            style: contentTextStyle,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Widget de utilidad para mostrar el campo de Dificultad (Texto simple)
  Widget _buildDifficultyDisplay(BuildContext context, int difficulty) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.colorScheme.surface;
    final onBackground = theme.colorScheme.onBackground;

    final difficultyText = dificultadMap[difficulty] ?? 'N/A';

    final TextStyle sectionTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: onBackground,
    );
    final TextStyle contentTextStyle = TextStyle(
      fontSize: 16,
      color: onBackground,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¿Qué tan difícil fue hoy?', style: sectionTitleStyle),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: cardColor, // Fondo dinámico
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primaryColor.withOpacity(0.5)),
          ),
          child: Text(
            difficultyText,
            style: contentTextStyle.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onBackground = theme.colorScheme.onBackground;
    final cardColor = theme.colorScheme.surface;

    // Título principal con la fecha formateada
    final DateFormat formatter = DateFormat('dd');
    final String day = formatter.format(registro.fecha);
    final String monthName = _dayjsMonthName(registro.fecha);

    // El color del número del día depende del estado
    final Color dayNumberColor = _getStateColor(registro.estado);

    // Estilos dinámicos
    final TextStyle sectionTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: onBackground, // Título de sección usa onBackground
    );

    return Scaffold(
      // Ya no tiene backgroundColor fijo, usa theme.scaffoldBackgroundColor
      appBar: AppBar(
        // Los colores de AppBar se heredan de theme.appBarTheme
        elevation: 0,
        title: Text('Cómo te fue este día', style: sectionTitleStyle.copyWith(fontSize: 20, color: primaryColor)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- TÍTULO PRINCIPAL CON FECHA Y ESTADO ---
            Row(
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: dayNumberColor, // Color basado en el estado (verde/amarillo/rojo)
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'de $monthName',
                  style: sectionTitleStyle.copyWith(fontSize: 24, fontWeight: FontWeight.normal, color: onBackground),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- VECES REALIZADAS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('¿Cuántas veces lo hiciste?', style: sectionTitleStyle),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryColor),
                    borderRadius: BorderRadius.circular(5),
                    color: cardColor, // Fondo dinámico
                  ),
                  child: Text(
                    registro.vecesRealizadas.toString(),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- SENTIMIENTO (Caja de texto de solo lectura) ---
            _buildReadOnlyField(
              context,
              '¿Cómo te sentiste al hacerlo?',
              registro.sentimiento ?? 'No se registró sentimiento.',
            ),

            // --- MOTIVO (Caja de texto de solo lectura) ---
            _buildReadOnlyField(
              context,
              '¿Por qué lo hiciste?',
              registro.motivo ?? 'No se registró motivo.',
            ),

            // --- DIFICULTAD (Texto simple sin Dropdown) ---
            _buildDifficultyDisplay(context, registro.dificultad),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Función auxiliar para obtener el color basado en el estado (Colores semánticos fijos)
  Color _getStateColor(int estado) {
    switch (estado) {
      case 3: return const Color(0xFF7D9C68); // successColor (Verde)
      case 2: return const Color(0xFFFFC107); // warningColor (Amarillo)
      case 1: return const Color(0xFFDC3545); // failureColor (Rojo)
      default: return Colors.grey;
    }
  }

  // Función auxiliar para obtener el nombre del mes en español
  String _dayjsMonthName(DateTime date) {
    switch (date.month) {
      case 1: return 'Enero';
      case 2: return 'Febrero';
      case 3: return 'Marzo';
      case 4: return 'Abril';
      case 5: return 'Mayo';
      case 6: return 'Junio';
      case 7: return 'Julio';
      case 8: return 'Agosto';
      case 9: return 'Septiembre';
      case 10: return 'Octubre';
      case 11: return 'Noviembre';
      case 12: return 'Diciembre';
      default: return '';
    }
  }
}