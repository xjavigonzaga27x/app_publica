// lib/models/territorio.dart
class Territorio {
  final String id;
  final String nombre;
  final String descripcion;

  Territorio({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  factory Territorio.fromFirestore(Map<String, dynamic> data, String id) {
    return Territorio(
      id: id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'nombre': nombre, 'descripcion': descripcion};
  }
}
