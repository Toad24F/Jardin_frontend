import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/habito.dart';

// Provider que maneja la lista de hábitos de forma asíncrona.
final habitosProvider = FutureProvider<List<Habito>>((ref) async {
  // Aseguramos que el AuthService esté listo
  final authService = ref.watch(authServiceProvider);

  // Llamamos al método que consume la API
  return authService.getHabitos();
});