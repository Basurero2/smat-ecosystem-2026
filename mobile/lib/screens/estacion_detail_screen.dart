import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EstacionDetailScreen extends StatefulWidget {
  final int estacionId;
  final String nombre;

  const EstacionDetailScreen({super.key, required this.estacionId, required this.nombre});

  @override
  State<EstacionDetailScreen> createState() => _EstacionDetailScreenState();
}

class _EstacionDetailScreenState extends State<EstacionDetailScreen> {
  // Ajusta la IP según tu configuración
  final String baseUrl = "http://127.0.0.1:8000";

  Future<Map<String, dynamic>> fetchHistorial() async {
    final response = await http.get(Uri.parse("$baseUrl/estaciones/${widget.estacionId}/historial"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("No se pudo cargar el historial");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nombre)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchHistorial(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!;
          final List lecturas = data['lecturas'];

          return Column(
            children: [
              Card(margin: const EdgeInsets.all(16), child: ListTile(title: Text("Promedio: ${data['promedio']} cm"))),
              Expanded(
                child: ListView.builder(
                  itemCount: lecturas.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text("Lectura ${index + 1}"),
                    trailing: Text("${lecturas[index]} cm", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}