class Station {
  final int? id;
  final String name;
  final String location;

  Station({this.id, required this.name, required this.location});

  // Para convertir el JSON que viene de FastAPI a un objeto de Flutter
  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      name: json['name'],
      location: json['location'],
    );
  }

  // Para enviar datos de Flutter a FastAPI
  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
  };
}