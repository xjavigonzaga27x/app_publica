class Hermano {
  final String id;
  final String nombre;
  final bool activo;
  final String?
  identificador; // Campo adicional para distinguir personas con mismo nombre
  final String? notas; // Notas opcionales sobre el hermano

  Hermano({
    required this.id,
    required this.nombre,
    required this.activo,
    this.identificador,
    this.notas,
  });

  // Nombre para mostrar (incluye identificador si existe)
  String get nombreCompleto =>
      identificador != null && identificador!.isNotEmpty
          ? '$nombre ($identificador)'
          : nombre;

  factory Hermano.fromFirestore(Map<String, dynamic> data, String id) {
    return Hermano(
      id: id,
      nombre: data['nombre'] ?? '',
      activo: data['activo'] ?? false,
      identificador: data['identificador'],
      notas: data['notas'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'activo': activo,
      'identificador': identificador,
      'notas': notas,
    };
  }

  Hermano copyWith({
    String? nombre,
    bool? activo,
    String? identificador,
    String? notas,
  }) {
    return Hermano(
      id: this.id,
      nombre: nombre ?? this.nombre,
      activo: activo ?? this.activo,
      identificador: identificador ?? this.identificador,
      notas: notas ?? this.notas,
    );
  }
}
