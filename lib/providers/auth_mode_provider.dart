import 'package:flutter_riverpod/flutter_riverpod.dart';

// Definimos los dos estados posibles
enum AuthMode { login, register }

// Provider para el modo de autenticación, por defecto es Login
final authModeProvider = StateProvider<AuthMode>((ref) => AuthMode.login);