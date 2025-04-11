import 'package:flutter/material.dart';
import 'package:app_p_publica/models/horario.dart';
import 'package:intl/intl.dart';

class HorarioListTile extends StatelessWidget {
  final Horario horario;
  final VoidCallback? onTap;

  const HorarioListTile({super.key, required this.horario, this.onTap});

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

    return ListTile(
      onTap: onTap,
      leading: Container(width: 8, color: colorDia),
      title: Text(
        '${_formatTimeOfDay(horario.horaInicio)} - ${_formatTimeOfDay(horario.horaFin)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(horario.hermanoNombre ?? 'Predicador no especificado'),
          Text(
            horario.territorioNombre ?? 'Territorio no especificado',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorDia,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          horario.dia,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
