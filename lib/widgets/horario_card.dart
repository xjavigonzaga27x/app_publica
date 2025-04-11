import 'package:flutter/material.dart';
import 'package:app_p_publica/models/horario.dart';
import 'package:intl/intl.dart';

class HorarioCard extends StatelessWidget {
  final Horario horario;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HorarioCard({
    super.key,
    required this.horario,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.Hm();
    return format.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Colores según el día
    final Map<String, Color> coloresDias = {
      'Lunes': Colors.blue[100]!,
      'Martes': Colors.green[100]!,
      'Miércoles': Colors.amber[100]!,
      'Jueves': Colors.deepOrange[100]!,
      'Viernes': Colors.purple[100]!,
      'Sábado': Colors.teal[100]!,
      'Domingo': Colors.red[100]!,
    };

    final colorDia = coloresDias[horario.dia] ?? theme.colorScheme.surface;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: colorDia, width: 8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        horario.hermanoNombre ?? 'Hermano no especificado',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        horario.territorioNombre ??
                            'Territorio no especificado',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorDia,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      horario.dia,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatTimeOfDay(horario.horaInicio)} - ${_formatTimeOfDay(horario.horaFin)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
