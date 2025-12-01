// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constantes de la API
const String baseUrl = 'http://192.168.100.25:3000';
const String loginUrl = '$baseUrl/auth/login';
const String registerUrl = '$baseUrl/usuarios';

// Modelos de Datos (para tipado seguro)
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

class AuthService {
  final Dio _dio = Dio();
  final SharedPreferences _prefs;

  AuthService(this._prefs);

  // Guarda el token JWT en el almacenamiento seguro
  Future<void> saveToken(String token) async {
    await _prefs.setString('accessToken', token);
  }

  // Intenta iniciar sesión y retorna un objeto de respuesta
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        loginUrl,
        data: {
          "email": email,
          "password": password,
        },
      );

      // El backend retorna { message: 'Login exitoso', access_token: '...' }
      final authResponse = AuthResponse.fromJson(response.data);
      await saveToken(authResponse.accessToken); // Guardar token al iniciar sesión
      return authResponse;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Error de red al iniciar sesión.';
    }
  }

  // Intenta registrar un nuevo usuario
  Future<AuthResponse> register(String nombre, String email, String password) async {
    try {
      // 1. POST a /usuarios para crear la cuenta
      await _dio.post(
        registerUrl,
        data: {
          "nombre": nombre,
          "email": email,
          "password": password,
        },
      );

      // 2. Una vez registrado, hacemos login automáticamente
      final authResponse = await login(email, password);
      return authResponse;

    } on DioException catch (e) {
      // El backend de NestJS devuelve el error de validación (409 Conflict)
      throw e.response?.data['message'] ?? 'Error de red al registrar usuario.';
    }
  }
}

// Provider de SharedPreferences. Lanza un error si no se ha sobreescrito.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Provider del servicio de autenticación (requiere SharedPreferences)
final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(prefs);
});
