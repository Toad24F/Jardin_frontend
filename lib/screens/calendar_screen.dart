import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/habito.dart';
import '../models/registro_dia.dart';
import '../providers/habitos_provider.dart';
import '../services/auth_service.dart';
import 'log_day_screen.dart';
import 'daily_log_detail_screen.dart'; // Importar la nueva pantalla de detalle

// Colores y Estilos
const Color primaryColor = Color(0xFF6C4B4B);
const Color lightBackgroundColor = Color(0xFFEFE8DE);
const Color accentGreen = Color(0xFF7D9C68);
const Color successColor = Color(0xFF7D9C68); // Verde (Estado 3)
const Color warningColor = Color(0xFFFFC107); // Amarillo (Estado 2)
const Color failureColor = Color(0xFFDC3545); // Rojo (Estado 1)
const Color todayDotColor = Colors.blue; // NUEVO: Azul para el indicador de "Hoy"

// Proveedor de Registros para el Calendario
final currentHabitRegistrosProvider = FutureProvider.family<List<RegistroDia>, String>((ref, habitId) async {
  final authService = ref.watch(authServiceProvider);
  // Esta línea dispara el GET /registros. Si el provider se invalida, esta función se ejecuta de nuevo.
  return authService.getRegistros(habitId);
});

// Modelo para los datos del día seleccionado
class DayInfo {
  final String date;
  final int vecesRealizadas;
  final String? sentimiento;
  final String? motivo;
  final int dificultad;
  final int estado;
  final RegistroDia registroCompleto; // Guardamos el objeto completo para la navegación

  DayInfo.fromRegistro(RegistroDia r) :
        date = "${r.fecha.day}/${r.fecha.month}",
        vecesRealizadas = r.vecesRealizadas,
        sentimiento = r.sentimiento,
        motivo = r.motivo,
        dificultad = r.dificultad,
        estado = r.estado,
        registroCompleto = r; // Aquí guardamos el objeto

  Color get color {
    switch (estado) {
      case 3: return successColor;
      case 2: return warningColor;
      case 1: return failureColor;
      default: return Colors.grey;
    }
  }
}

class CalendarScreen extends ConsumerStatefulWidget {
  final Habito habito;
  const CalendarScreen({super.key, required this.habito});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  late DateTime _selectedDay;
  DayInfo? _selectedDayData;
  late final DateTime _firstDayOfMonth;
  late final DateTime _lastDayOfMonth;

  // Mapeo de registros para acceso rápido por fecha (sin hora)
  Map<DateTime, RegistroDia> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // La fecha más antigua permitida es el mes de creación del hábito.
    _firstDayOfMonth = DateTime(widget.habito.createdAt.year, widget.habito.createdAt.month, 1);
    // La fecha más reciente permitida es el final del mes actual
    _lastDayOfMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    // Al inicio, cargamos si el día actual tiene un registro
    _loadDayData(DateTime.now());
  }

  // Función de ayuda para normalizar la fecha (solo año, mes, día)
  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  // Carga los datos del día seleccionado del mapa _events
  void _loadDayData(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    final registro = _events[normalizedDate];

    setState(() {
      _selectedDay = normalizedDate;
      _focusedDay = normalizedDate;
      _selectedDayData = registro != null ? DayInfo.fromRegistro(registro) : null;
    });
  }

  // Define los eventos (puntos de color) para TableCalendar
  List<RegistroDia> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] != null ? [_events[_normalizeDate(day)]!] : [];
  }

  // Genera el widget de la barra de progreso de estado
  Widget _buildStatusBar(List<RegistroDia> registros) {
    if (registros.isEmpty) {
      return const Center(child: Text("No hay datos para calcular el progreso.", style: TextStyle(color: primaryColor)));
    }

    // Contadores para cada estado
    int countGreen = 0; // Estado 3
    int countYellow = 0; // Estado 2
    int countRed = 0; // Estado 1

    for (var r in registros) {
      if (r.estado == 3) countGreen++;
      if (r.estado == 2) countYellow++;
      if (r.estado == 1) countRed++;
    }

    final total = countGreen + countYellow + countRed;
    if (total == 0) return const SizedBox.shrink(); // Evitar división por cero

    // Calcular porcentajes
    final pGreen = countGreen / total;
    final pYellow = countYellow / total;
    final pRed = countRed / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Cómo te ha ido?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 20,
            child: Row(
              children: [
                // Barra Verde
                if (pGreen > 0) Expanded(flex: (pGreen * 100).toInt(), child: Container(color: successColor)),
                // Barra Amarilla
                if (pYellow > 0) Expanded(flex: (pYellow * 100).toInt(), child: Container(color: warningColor)),
                // Barra Roja
                if (pRed > 0) Expanded(flex: (pRed * 100).toInt(), child: Container(color: failureColor)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Maneja la navegación al tocar un día
  void _handleDayTap(BuildContext context) {
    // Esta función solo se llama desde onDaySelected para días registrados que NO son hoy.
    if (_selectedDayData != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DailyLogDetailScreen(registro: _selectedDayData!.registroCompleto),
        ),
      );
    }
  }

  // NUEVO: Método para manejar la eliminación del hábito
  void _deleteHabit(BuildContext context) async {
    // Diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
              '¿Estás seguro de que deseas eliminar el hábito "${widget.habito.nombreHabito}"? Esta acción es irreversible.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: primaryColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: failureColor, // Rojo para eliminar
              ),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Proceder con la eliminación
      final authService = ref.read(authServiceProvider);
      try {
        // Llama a la nueva función del servicio
        await authService.deleteHabito(widget.habito.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Hábito eliminado con éxito.'),
                backgroundColor: successColor),
          );

          // Invalida el provider de hábitos para que HomeScreen se actualice
          ref.invalidate(habitosProvider);

          // Navega de vuelta a HomeScreen
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al eliminar el hábito: $e'),
                backgroundColor: failureColor),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final TextStyle appBarTitleStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor);

    // 1. Observamos los registros del hábito
    final registrosAsyncValue = ref.watch(currentHabitRegistrosProvider(widget.habito.id));

    // 2. Procesar los datos para el calendario
    registrosAsyncValue.whenData((registros) {
      // SOLO cargar eventos si el mapa está vacío.
      // Si el provider se invalida, events será limpiado en la función de recarga exitosa.
      if (registros.isNotEmpty && _events.isEmpty) {
        // Mapeamos registros a un mapa de eventos (DateTime -> RegistroDia)
        final newEvents = {
          for (var r in registros)
            _normalizeDate(r.fecha): r
        };
        // Usamos WidgetsBinding.instance.addPostFrameCallback para asegurar que
        // setState se llama después de la fase de construcción
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _events = newEvents;
              // Forzar a recargar los datos del día actual
              _loadDayData(_selectedDay);
            });
          }
        });
      }
    });

    // 3. Verifica si el día de hoy ya fue registrado
    final isTodayRegistered = _selectedDayData != null && isSameDay(_selectedDay, DateTime.now());
    final isToday = isSameDay(_selectedDay, DateTime.now());

    // Calcula la fecha de creación del hábito (para la restricción de navegación)
    final DateTime firstDayAllowed = _firstDayOfMonth;

    // Calcula el porcentaje de la barra (por ahora, solo si los datos están listos)
    final statusBar = registrosAsyncValue.when(
      data: (registros) => _buildStatusBar(registros),
      loading: () => const Center(child: Text("Calculando progreso...")),
      error: (e, s) => const Center(child: Text("Error al cargar datos de progreso.")),
    );


    return Scaffold(
      backgroundColor: lightBackgroundColor,
      appBar: AppBar(
        title: Text('Tu mes: ${widget.habito.nombreHabito}', style: appBarTitleStyle),
        backgroundColor: lightBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Botón de Recarga Manual
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryColor),
            onPressed: () {
              // Limpia el estado local y fuerza la recarga del provider
              setState(() { _events = {}; });
              ref.invalidate(currentHabitRegistrosProvider(widget.habito.id));
              ref.invalidate(habitosProvider); // Recargar también la lista principal por si cambia la mata
            },
            tooltip: 'Recargar registros',
          ),
          // NUEVO: Botón de Eliminación (reemplaza 'Otros días')
          IconButton(
            icon: const Icon(Icons.delete_forever, color: failureColor),
            onPressed: () => _deleteHabit(context),
            tooltip: 'Eliminar Hábito',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: <Widget>[
            // --- CALENDARIO (TableCalendar) ---
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7EEDC),        // crema vintage
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6A4032), width: 1.4), // borde café
              ),
              child: TableCalendar(
                focusedDay: _focusedDay,
                firstDay: firstDayAllowed,
                lastDay: _lastDayOfMonth,
                currentDay: _selectedDay,

                // ------------------ HEADER (ENERO, FEBRERO...) ------------------
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextFormatter: (date, locale) =>
                  '${date.dayjsMonthName().toUpperCase()} ${date.year}',
                  titleTextStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A4032), // café vintage
                  ),

                  // Flechas estilo discreto (parecido a la imagen)
                  leftChevronIcon: const Icon(Icons.arrow_back_ios, color: Color(0xFF6A4032)),
                  rightChevronIcon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF6A4032)),
                  headerPadding: const EdgeInsets.only(top: 4, bottom: 6),
                ),

                // ------------------ DIAS DE LA SEMANA ------------------
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A4032), // café
                  ),
                  weekendStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A4032),
                  ),
                ),

                // ------------------ ESTILOS DEL CALENDARIO ------------------
                calendarStyle: CalendarStyle(
                  defaultTextStyle: const TextStyle(color: Color(0xFF6A4032), fontWeight: FontWeight.w600),
                  weekendTextStyle: const TextStyle(color: Color(0xFF6A4032)),
                  outsideDaysVisible: false,

                  todayDecoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.25),  // rojito suave como la imagen
                    shape: BoxShape.circle,
                  ),

                  selectedDecoration: const BoxDecoration(
                    color: primaryColor, // rojo sólido
                    shape: BoxShape.circle,
                  ),

                  todayTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A4032),
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // ------------------ TUS EVENTOS (bolitas de colores) ------------------
                calendarBuilders: CalendarBuilders(
                  // NUEVO: Builder para mostrar el punto azul en el día de hoy
                  todayBuilder: (context, day, focusedDay) {
                    // Solo si es el día de hoy y no tiene un registro asociado, mostramos el punto
                    final events = _getEventsForDay(day);
                    if (!isSameDay(day, DateTime.now()) || events.isNotEmpty) {
                      return null; // Permite que el builder por defecto de TableCalendar tome el control
                    }

                    // Renderizamos el día de hoy (sin evento) con el punto azul.
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Contenido del día (número)
                        Container(
                          margin: const EdgeInsets.all(4.0),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            // Replicamos la decoración de 'today' de CalendarStyle para mantener el círculo suave
                            color: primaryColor.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            // Usamos el estilo predeterminado para el texto del día.
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6A4032),
                            ),
                          ),
                        ),
                        // Pequeño punto azul arriba del número
                        const Positioned(
                          top: 8, // Ajuste para que quede justo arriba
                          child: CircleAvatar(
                            radius: 3,
                            backgroundColor: todayDotColor,
                          ),
                        ),
                      ],
                    );
                  },

                  defaultBuilder: (context, day, focusedDay) {
                    final events = _getEventsForDay(day);
                    if (events.isNotEmpty) {
                      final registro = events.first;
                      Color dayColor = DayInfo.fromRegistro(registro).color;

                      return GestureDetector( // Hacemos cada día con registro clickeable
                        onTap: () {
                          // Si el día tiene registro, siempre carga y navega
                          _loadDayData(day); // Carga la data del día
                          _handleDayTap(context); // Navega al detalle
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: dayColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                // Manejo de la selección
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  // Solo permitir seleccionar si no es un día futuro
                  if (selectedDay.isAfter(DateTime.now()) && !isSameDay(selectedDay, DateTime.now())) {
                    return;
                  }

                  // Si seleccionamos un día con registro, navegamos al detalle
                  final isRegisteredDay = _events[_normalizeDate(selectedDay)] != null;

                  _loadDayData(selectedDay);
                  setState(() => _focusedDay = focusedDay);

                  // CORRECCIÓN DE NAVEGACIÓN: Si el día está registrado, navegamos al detalle.
                  // Esto cubre el día de hoy o cualquier día pasado con registro.
                  if (isRegisteredDay) {
                    // Llama a la navegación después de cargar la data
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _handleDayTap(context);
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                // Definimos los eventos
                eventLoader: _getEventsForDay,
              ),
            ),

            const SizedBox(height: 20),

            // --- BARRA DE ESTADO (Porcentaje de colores) ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: statusBar,
            ),

            // --- BOTÓN INFERIOR (Registrar / Ya Registrado) ---
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              // El botón ahora siempre se muestra, pero la lógica interna
              // de `_buildLogButton` decidirá si es clickeable.
              child: _buildLogButton(isToday, isTodayRegistered),
            ),
          ],
        ),
      ),
    );
  }

  // Widget de utilidad para mostrar info del día
  Widget _buildInfoRow(String label, String value, {Color? color}) {
    const TextStyle descriptionTextStyle = TextStyle(
      fontSize: 16,
      color: Colors.grey,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: descriptionTextStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
          Text(value, style: descriptionTextStyle.copyWith(color: color ?? Colors.black)),
        ],
      ),
    );
  }

  // Widget para el botón inferior
  Widget _buildLogButton(bool isToday, bool isRegistered) {
    // Lógica original de ocultamiento eliminada. El botón siempre se muestra.

    // Si no es hoy, mostramos el botón pero deshabilitado o con otro texto
    String text = 'Registrar Día';
    Color btnColor = primaryColor;
    bool isClickable = true;

    if (isToday) {
      if (isRegistered) {
        text = 'Ya registraste tu informe diario';
        btnColor = accentGreen.withOpacity(0.6);
        isClickable = false;
      }
    } else {
      // Si el día seleccionado no es hoy, el botón está deshabilitado
      text = 'Selecciona el día de hoy para registrar';
      btnColor = primaryColor.withOpacity(0.4);
      isClickable = false;
    }


    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isClickable ? () async {
          // Navegar a la pantalla de LogDayScreen y esperar el resultado
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => LogDayScreen(habitoId: widget.habito.id)),
          );

          // Si el registro fue exitoso (result == true), forzamos la recarga de registros
          if (result == true) {
            // Invalidamos el provider para que haga una nueva llamada GET
            ref.invalidate(currentHabitRegistrosProvider(widget.habito.id));
            // También invalidamos el provider de hábitos general, porque la etapa de la mata pudo cambiar.
            ref.invalidate(habitosProvider);
            // Limpiamos los eventos y esperamos la nueva carga
            _events = {};
          }
        } : null, // Deshabilita si no es clickeable
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: const Color(0xFFF7EEDC), // Color de texto claro para botones oscuros
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          // Usamos el color del botón (btnColor) para el fondo
          disabledBackgroundColor: btnColor,
        ),
        child: Text(text, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

// Extensión para obtener el nombre del mes
extension on DateTime {
  String dayjsMonthName() {
    switch (this.month) {
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