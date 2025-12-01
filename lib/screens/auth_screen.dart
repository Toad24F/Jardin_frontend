import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart'; // Importar el servicio

// --- Definición del Estado de la Pantalla ---
enum AuthMode { login, register }

// Provider para el modo de autenticación, por defecto es Login
final authModeProvider = StateProvider<AuthMode>((ref) => AuthMode.login);

// --- Colores y Estilos ---
const Color primaryTextColor = Color(0xFF6C4B4B);
const Color backgroundColor = Color(0xFFEFE8DE);
const Color buttonColor = Colors.black;
const Color buttonTextColor = Colors.white;
const Color inputFillColor = Colors.white;

final TextStyle appTitleStyle = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: primaryTextColor,
  fontFamily: 'Pacifico',
);

final TextStyle sectionTitleStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

final TextStyle descriptionTextStyle = TextStyle(
  fontSize: 16,
  color: Colors.grey[700],
);

final TextStyle termsTextStyle = TextStyle(
  fontSize: 12,
  color: Colors.grey[600],
);
// -------------------------


class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  // Controladores para los campos de texto
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  void _showError(dynamic error) {
    // Muestra el error usando un SnackBar (alerta temporal)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Error: ${error.toString()}',
            style: const TextStyle(color: Colors.white)
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  // --- Lógica de Navegación Exitosa (temporal) ---
  void _goToHome() {
    // En una aplicación real, aquí navegarías a la pantalla principal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Autenticación Exitosa! Token guardado.'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implementar Navigator.pushReplacement para ir a HomeScreen
  }

  // --- Lógica de Login (Consumo de API) ---
  void _handleLogin() async {
    // Validaciones básicas de campos
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      return _showError("Por favor, rellena todos los campos.");
    }

    try {
      // Aseguramos que el servicio de autenticación esté disponible
      final authService = ref.read(authServiceProvider);
      setState(() => _isLoading = true);

      await authService.login(
        emailController.text,
        passwordController.text,
      );

      _goToHome();

    } catch (e) {
      _showError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Lógica de Registro (Consumo de API + Login Automático) ---
  void _handleRegister() async {
    // Validaciones básicas de campos
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      return _showError("Por favor, rellena todos los campos.");
    }

    try {
      // Aseguramos que el servicio de autenticación esté disponible
      final authService = ref.read(authServiceProvider);
      setState(() => _isLoading = true);

      // La función register incluye el login automático
      await authService.register(
        nameController.text,
        emailController.text,
        passwordController.text,
      );

      _goToHome();

    } catch (e) {
      _showError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Widget de utilidad para campos de texto
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required bool isPassword,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        fillColor: inputFillColor,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authMode = ref.watch(authModeProvider);
    final isLoginMode = authMode == AuthMode.login;

    // --- Textos dinámicos ---
    final titleText = isLoginMode ? 'Inicia sesión con tu cuenta' : 'Crea una cuenta';
    final descriptionText = isLoginMode
        ? 'Ingresa tu correo electrónico y contraseña para iniciar sesión en esta aplicación.'
        : 'Ingresa los siguientes datos para registrar una nueva cuenta.';
    final mainButtonText = isLoginMode ? 'Iniciar Sesión' : 'Registrarse';
    final switchButtonText = isLoginMode ? 'Registrarse' : 'Iniciar Sesión';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Aquí va la imagen de la maceta
                Image.asset(
                    'assets/plant_Icon.png',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.grass, size: 100, color: primaryTextColor) // Fallback si no hay assets
                ),
                const SizedBox(height: 20),
                Text('Jardín de Hábitos', style: appTitleStyle),
                const SizedBox(height: 30),

                // --- Títulos dinámicos ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(titleText, style: sectionTitleStyle),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(descriptionText, style: descriptionTextStyle),
                ),
                const SizedBox(height: 30),

                // --- Campos de Entrada Dinámicos ---
                if (!isLoginMode) ...[
                  // Campo Nombre (solo en modo Registro)
                  _buildInputField(
                    controller: nameController,
                    hintText: 'Nombre',
                    isPassword: false,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 15),
                ],

                // Campo Correo Electrónico
                _buildInputField(
                  controller: emailController,
                  hintText: 'Correo Electrónico',
                  isPassword: false,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                // Campo Contraseña
                _buildInputField(
                  controller: passwordController,
                  hintText: 'Contraseña (mínimo 6 caracteres)',
                  isPassword: true,
                  keyboardType: TextInputType.visiblePassword,
                ),
                const SizedBox(height: 20),

                // --- Botón Principal Dinámico (con indicador de carga) ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      if (isLoginMode) {
                        _handleLogin();
                      } else {
                        _handleRegister();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: buttonTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: buttonTextColor)
                        : Text(mainButtonText, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Botón de Cambio de Modo ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () {
                      ref.read(authModeProvider.notifier).state = isLoginMode
                          ? AuthMode.register
                          : AuthMode.login;

                      // Limpiar campos al cambiar de modo
                      nameController.clear();
                      emailController.clear();
                      passwordController.clear();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: buttonColor,
                      side: const BorderSide(color: buttonColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cambiar a $switchButtonText',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Texto de Términos y Política de privacidad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text.rich(
                    TextSpan(
                      text: 'Al hacer clic en continuar, aceptas nuestros ',
                      style: termsTextStyle,
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Términos de servicio',
                          style: termsTextStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                          text: ' y ',
                          style: termsTextStyle,
                        ),
                        TextSpan(
                          text: 'Política de privacidad',
                          style: termsTextStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}