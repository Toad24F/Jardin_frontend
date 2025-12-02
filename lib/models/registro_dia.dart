// lib/models/registro_dia.dart

class RegistroDia {
  final String id;
  final DateTime fecha;
  final int vecesRealizadas;
  final String? sentimiento;
  final String? motivo;
  final int dificultad;
  final String idHabito;
  final int estado; // 1: Rojo (Mal), 2: Amarillo (Regular), 3: Verde (Bien)

  RegistroDia({
    required this.id,
    required this.fecha,
    required this.vecesRealizadas,
    this.sentimiento,
    this.motivo,
    required this.dificultad,
    required this.idHabito,
    required this.estado,
  });

  factory RegistroDia.fromJson(Map<String, dynamic> json) {
    // Convertimos la fecha (que viene como "2025-11-04") a DateTime
    DateTime parsedDate;
    if (json['fecha'] is String) {
      parsedDate = DateTime.parse(json['fecha'] as String);
    } else {
      // Manejar el caso si la fecha ya viene como objeto DateTime (poco probable en JSON)
      parsedDate = json['fecha'] as DateTime;
    }

    return RegistroDia(
      id: json['id'] as String,
      fecha: parsedDate,
      vecesRealizadas: json['veces_realizadas'] as int,
      sentimiento: json['sentimiento'] as String?,
      motivo: json['motivo'] as String?,
      dificultad: json['dificultad'] as int,
      idHabito: json['id_habito'] as String,
      estado: json['estado'] as int,
    );
  }
}