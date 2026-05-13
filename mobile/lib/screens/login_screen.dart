import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);

    // Llamamos al método que configuramos antes
    bool success = await _authService.login(
      _userController.text,
      _passController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      // Si el login es correcto, navegamos a la pantalla principal
      // Por ahora la mandaremos a una pantalla de "Home" que crearemos luego
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Bienvenido al sistema SMAT!')),
      );
      // Navigator.pushReplacementNamed(context, '/home'); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Usuario o contraseña incorrectos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SMAT - Iniciar Sesión')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userController,
              decoration: InputDecoration(labelText: 'Usuario'),
            ),
            TextField(
              controller: _passController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true, // Para que no se vea la clave
            ),
            SizedBox(height: 20),
            _isLoading 
              ? CircularProgressIndicator() 
              : ElevatedButton(
                  onPressed: _handleLogin,
                  child: Text('Entrar'),
                ),
          ],
        ),
      ),
    );
  }
}