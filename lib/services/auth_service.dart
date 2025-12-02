import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habito.dart';

// --- Constantes de la API ---
const String baseUrl = 'http://192.168.100.25:3000';
const String loginUrl = '$baseUrl/auth/login';
const String registerUrl = '$baseUrl/usuarios';
const String habitosUrl = '$baseUrl/habitos'; // Nueva URL para hábitos

// --- Modelos de Datos ---

class AuthResponse {
  final String accessToken;
  final String message;

  AuthResponse({required this.accessToken, required this.message});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      message: json['message'] as String,
    );
  }
}

// --- Servicio de Autenticación y Hábitos ---

class AuthService {
  final Dio _dio = Dio();
  final SharedPreferences _prefs;

  AuthService(this._prefs);

  // Guarda el token JWT en el almacenamiento local seguro
  Future<void> saveToken(String token) async {
    await _prefs.setString('accessToken', token);
  }

  // Retorna el token JWT si existe en el almacenamiento
  String? getToken() {
    return _prefs.getString('accessToken');
  }

  // Crea la cabecera de autorización JWT
  Options _getAuthOptions() {
    final token = getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Usuario no autenticado. Token JWT no encontrado.");
    }
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }
  // Obtiene todos los hábitos del usuario (GET /habitos)
  Future<List<Habito>> getHabitos() async {
    try {
      final response = await _dio.get(
        habitosUrl,
        options: _getAuthOptions(), // Incluye el token
      );

      // La respuesta es una lista de JSON, la mapeamos a List<Habito>
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Habito.fromJson(json))
            .toList();
      }
      return []; // Si no es una lista válida, retorna vacío

    } on DioException catch (e) {
      // Manejar el caso donde no hay hábitos (que el backend podría retornar como 404 o lista vacía)
      // Si el backend retorna 404 para lista vacía, NestJS lanza una NotFoundException (ej. RegistrosService)
      if (e.response?.statusCode == 404) {
        // El backend de HabitosService retorna lista vacía si no hay (no 404),
        // pero si en algún punto cambia, aquí lo manejamos.
        return [];
      }
      throw e.response?.data['message'] ?? 'Error al obtener los hábitos.';
    }
  }

  // Intenta iniciar sesión y guarda el token
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        loginUrl,
        data: {
          "email": email,
          "password": password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await saveToken(authResponse.accessToken);
      return authResponse;

    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de red al iniciar sesión.';
    }
  }

  // Intenta registrar un nuevo usuario y automáticamente inicia sesión
  Future<AuthResponse> register(String nombre, String email, String password) async {
    try {
      await _dio.post(
        registerUrl,
        data: {
          "nombre": nombre,
          "email": email,
          "password": password,
        },
      );

      final authResponse = await login(email, password);
      return authResponse;

    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de red al registrar usuario.';
    }
  }

  // --- Lógica de Hábitos ---

  // Crea un nuevo hábito (POST /habitos)
  Future<void> createHabit({
    required String nombreHabito,
    required int frecuenciaDiaria,
    String? notas,
  }) async {
    try {
      await _dio.post(
        habitosUrl,
        data: {
          "nombre_habito": nombreHabito,
          "frecuencia_diaria": frecuenciaDiaria,
          "notas": notas,
        },
        options: _getAuthOptions(), // Añadir la autorización JWT
      );
    } on DioException catch (e) {
      // El backend de NestJS devuelve errores de validación o 401 Unauthorized
      throw e.response?.data['message'] ?? 'Error al crear el hábito.';
    }
  }
}

// --- Providers de Riverpod (Se mantienen igual) ---

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences no ha sido inicializado.');
});

final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(prefs);
});