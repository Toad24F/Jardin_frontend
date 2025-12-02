// lib/models/habito.dart

class Habito {
  final String id;
  final String nombreHabito;
  final int frecuenciaDiaria;
  final String? notas;
  final DateTime createdAt;
  final int etapaMata; // Número de 1 a 15 para seleccionar la imagen
  final int calificadorCrecimiento;
  final String idUsuario;

  Habito({
    required this.id,
    required this.nombreHabito,
    required this.frecuenciaDiaria,
    this.notas,
    required this.createdAt,
    required this.etapaMata,
    required this.calificadorCrecimiento,
    required this.idUsuario,
  });

  factory Habito.fromJson(Map<String, dynamic> json) {
    return Habito(
      id: json['id'] as String,
      nombreHabito: json['nombre_habito'] as String,
      frecuenciaDiaria: json['frecuencia_diaria'] as int,
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      etapaMata: json['etapa_mata'] as int,
      calificadorCrecimiento: json['calificador_crecimiento'] as int,
      idUsuario: json['id_usuario'] as String,
    );
  }
}