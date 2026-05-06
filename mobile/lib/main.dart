import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile/services/auth_service.dart'; // Importante: Verifica esta ruta

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMAT Ecosystem',
      debugShowCheckedModeBanner: false,
      // EL RETO 6.3: El FutureBuilder decide qué pantalla mostrar al arrancar
      home: FutureBuilder<String?>(
        future: AuthService().getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // Si el token existe, vamos a la Home, si no, al Login
          if (snapshot.hasData && snapshot.data != null) {
            return const SMATHome();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

// --- PANTALLA DE LOGIN (Laboratorio 6.2) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  Future<void> _login() async {
    // CAMBIA ESTA URL POR TU IP DE LOGIN (Semana 4)
    final url = Uri.parse("http://192.168.0.114:8000/login"); 
    
    try {
      final response = await http.post(
        url,
        body: {'username': _userController.text, 'password': _passController.text},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // GUARDAMOS EL TOKEN (Persistencia)
        await AuthService().saveToken(data['access_token']);
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const SMATHome())
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Credenciales incorrectas"))
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login SMAT")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _userController, decoration: const InputDecoration(labelText: "Usuario")),
            TextField(controller: _passController, decoration: const InputDecoration(labelText: "Contraseña"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text("Ingresar"))
          ],
        ),
      ),
    );
  }
}

// --- TU PANTALLA DE HOME (La que ya tenías) ---
class SMATHome extends StatefulWidget {
  const SMATHome({super.key});
  @override
  State<SMATHome> createState() => _SMATHomeState();
}

class _SMATHomeState extends State<SMATHome> {
  final String backendUrl = "http://192.168.0.114:8000/estaciones/";

  Future<List<dynamic>> fetchEstaciones() async {
    final response = await http.get(Uri.parse(backendUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar estaciones');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMAT Móvil - UNMSM'),
        actions: [
          // Botón para cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const LoginScreen())
              );
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: fetchEstaciones(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('❌ Error: ${snapshot.error}'));
          } else {
            final estaciones = snapshot.data as List;
            return ListView.builder(
              itemCount: estaciones.length,
              itemBuilder: (context, index) => ListTile(
                leading: const Icon(Icons.satellite_alt, color: Colors.blue),
                title: Text(estaciones[index]['nombre']),
                subtitle: Text(estaciones[index]['ubicacion']),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () => setState(() {}),
      ),
    );
  }
}