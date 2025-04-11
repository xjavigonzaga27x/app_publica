// lib/models/horario.dart
import 'package:flutter/material.dart';

class Horario {
  final String id;
  final String hermanoId;
  final String territorioId;
  final String dia;
  final TimeOfDay horaInicio;
  final TimeOfDay horaFin;

  // Campos para mostrar información relacionada
  final String? hermanoNombre;
  final String? territorioNombre;

  Horario({
    required this.id,
    required this.hermanoId,
    required this.territorioId,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    this.hermanoNombre,
    this.territorioNombre,
  });

  factory Horario.fromFirestore(Map<String, dynamic> data, String id) {
    // Convertir Timestamp a TimeOfDay
    final inicioMinutos = data['horaInicioMinutos'] ?? 0;
    final finMinutos = data['horaFinMinutos'] ?? 0;

    return Horario(
      id: id,
      hermanoId: data['hermanoId'] ?? '',
      territorioId: data['territorioId'] ?? '',
      dia: data['dia'] ?? '',
      horaInicio: TimeOfDay(
        hour: inicioMinutos ~/ 60,
        minute: inicioMinutos % 60,
      ),
      horaFin: TimeOfDay(hour: finMinutos ~/ 60, minute: finMinutos % 60),
      hermanoNombre: data['hermanoNombre'],
      territorioNombre: data['territorioNombre'],
    );
  }

  Map<String, dynamic> toFirestore() {
    // Convertir TimeOfDay a minutos para almacenar en Firestore
    final inicioMinutos = horaInicio.hour * 60 + horaInicio.minute;
    final finMinutos = horaFin.hour * 60 + horaFin.minute;

    return {
      'hermanoId': hermanoId,
      'territorioId': territorioId,
      'dia': dia,
      'horaInicioMinutos': inicioMinutos,
      'horaFinMinutos': finMinutos,
    };
  }
}
