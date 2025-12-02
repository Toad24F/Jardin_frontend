import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

// Clave usada en SharedPreferences para guardar las posiciones
const String _positionsKey = 'habit_positions_map';

/**
 * Servicio para manejar la persistencia de la posición de los hábitos
 * de forma local usando SharedPreferences.
 */
class LocalHabitPositionService {
  final SharedPreferences _prefs;

  LocalHabitPositionService(this._prefs);

  /**
   * Carga el mapa de posiciones guardadas.
   * El formato guardado es Map<String, String>, donde el valor es "dx,dy".
   */
  Map<String, Offset> loadPositions() {
    final String? jsonString = _prefs.getString(_positionsKey);
    if (jsonString == null) {
      return {};
    }

    final Map<String, dynamic> rawMap = json.decode(jsonString);
    final Map<String, Offset> positions = {};

    rawMap.forEach((key, value) {
      // El valor es una cadena "dx,dy"
      final parts = (value as String).split(',');
      if (parts.length == 2) {
        positions[key] = Offset(
          double.tryParse(parts[0]) ?? 0.0,
          double.tryParse(parts[1]) ?? 0.0,
        );
      }
    });

    return positions;
  }

  /**
   * Guarda las posiciones actuales en SharedPreferences.
   */
  Future<void> savePositions(Map<String, Offset> positions) async {
    final Map<String, String> saveMap = {};

    positions.forEach((key, offset) {
      // Serializa el Offset a una cadena "dx,dy"
      saveMap[key] = '${offset.dx},${offset.dy}';
    });

    final String jsonString = json.encode(saveMap);
    await _prefs.setString(_positionsKey, jsonString);
  }
}

// Provider del servicio de almacenamiento local
final localStorageServiceProvider = Provider<LocalHabitPositionService>((ref) {
  // Aseguramos que sharedPreferencesProvider esté sobreescrito con la instancia real
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalHabitPositionService(prefs);
});