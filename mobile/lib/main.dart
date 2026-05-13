import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // <-- NUEVO: Para generar IDs aleatorios
import 'package:mobile/services/auth_service.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMAT Ecosystem',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<String?>(
        future: AuthService().getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
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

// --- PANTALLA DE LOGIN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  Future<void> _login() async {
    final url = Uri.parse("http://192.168.0.114:8000/login"); 
    
    try {
      final response = await http.post(
        url,
        body: {'username': _userController.text, 'password': _passController.text},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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

// --- PANTALLA DE HOME ---
class SMATHome extends StatefulWidget {
  const SMATHome({super.key});
  @override
  State<SMATHome> createState() => _SMATHomeState();
}

class _SMATHomeState extends State<SMATHome> {
  final String backendUrl = "http://192.168.0.114:8000/estaciones/";

  Future<List<dynamic>> fetchEstaciones() async {
    try {
      final response = await http.get(Uri.parse(backendUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión');
    }
  }
  

// --- RETO 6.2: POST para crear estación (Formato JSON) ---
  Future<void> crearEstacion(String nombre, String ubicacion) async {
    final token = await AuthService().getToken();
    final randomId = Random().nextInt(10000); 
    
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json', // Le decimos que enviamos JSON
          'Authorization': 'Bearer $token', 
        },
        body: json.encode({
          'id': randomId,
          'nombre': nombre,
          'ubicacion': ubicacion,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {}); // Refresca la lista automáticamente
      } else {
        print("Error del servidor: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al crear: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMAT Móvil - UNMSM'),
        actions: [
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
      // --- NUEVO: RefreshIndicator envuelve todo el cuerpo ---
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // Recarga la pantalla
        },
        child: FutureBuilder(
          future: fetchEstaciones(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              // --- NUEVO: Pantalla de error amigable para el Lab 7.1 ---
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(), // Permite deslizar incluso con error
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No se pudo conectar con SMAT', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text("Reintentar"),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            } else {
              final estaciones = snapshot.data as List;
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(), // Crucial para Pull-to-refresh
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
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              String n = '';
              String u = '';
              return AlertDialog(
                title: const Text("Nueva Estación"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(onChanged: (v) => n = v, decoration: const InputDecoration(labelText: "Nombre")),
                    TextField(onChanged: (v) => u = v, decoration: const InputDecoration(labelText: "Ubicación")),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                  ElevatedButton(
                    onPressed: () {
                      if(n.isNotEmpty && u.isNotEmpty) {
                        crearEstacion(n, u);
                        Navigator.pop(context);
                      }
                    }, 
                    child: const Text("Guardar")
                  ),
                ],
              );
            }
          );
        },
      ),
    );
  }
}