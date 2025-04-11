import 'package:flutter/material.dart';
import 'package:app_p_publica/models/hermano.dart';
import 'package:app_p_publica/models/territorio.dart';
import 'package:app_p_publica/models/horario.dart';
import 'package:intl/intl.dart';

class HorarioForm extends StatefulWidget {
  final Horario? horario;
  final List<Hermano> hermanos;
  final List<Territorio> territorios;
  final Function(Horario horario) onSubmit;

  const HorarioForm({
    super.key,
    this.horario,
    required this.hermanos,
    required this.territorios,
    required this.onSubmit,
  });

  @override
  State<HorarioForm> createState() => _HorarioFormState();
}

class _HorarioFormState extends State<HorarioForm> {
  late String _hermanoId;
  late String _territorioId;
  late String _dia;
  late TimeOfDay _horaInicio;
  late TimeOfDay _horaFin;
  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();

    final esEdicion = widget.horario != null;

    _hermanoId =
        esEdicion
            ? widget.horario!.hermanoId
            : (widget.hermanos.isNotEmpty ? widget.hermanos[0].id : '');

    _territorioId =
        esEdicion
            ? widget.horario!.territorioId
            : (widget.territorios.isNotEmpty ? widget.territorios[0].id : '');

    _dia = esEdicion ? widget.horario!.dia : 'Lunes';

    _horaInicio =
        esEdicion
            ? widget.horario!.horaInicio
            : const TimeOfDay(hour: 8, minute: 0);

    _horaFin =
        esEdicion
            ? widget.horario!.horaFin
            : const TimeOfDay(hour: 10, minute: 0);
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.Hm();
    return format.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.horario != null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              esEdicion ? 'Editar Horario' : 'Nuevo Horario',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Selección de hermano
            const Text(
              'Hermano:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.hermanos.isEmpty)
              const Text(
                'No hay hermanos registrados',
                style: TextStyle(color: Colors.red),
              )
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                isExpanded: true,
                value: _hermanoId,
                items:
                    widget.hermanos.map((hermano) {
                      return DropdownMenuItem<String>(
                        value: hermano.id,
                        child: Text(hermano.nombre),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _hermanoId = value;
                    });
                  }
                },
              ),
            const SizedBox(height: 16),

            // Selección de territorio
            const Text(
              'Territorio:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.territorios.isEmpty)
              const Text(
                'No hay territorios registrados',
                style: TextStyle(color: Colors.red),
              )
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                isExpanded: true,
                value: _territorioId,
                items:
                    widget.territorios.map((territorio) {
                      return DropdownMenuItem<String>(
                        value: territorio.id,
                        child: Text(territorio.nombre),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _territorioId = value;
                    });
                  }
                },
              ),
            const SizedBox(height: 16),

            // Selección de día
            const Text('Día:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              isExpanded: true,
              value: _dia,
              items:
                  _diasSemana.map((dia) {
                    return DropdownMenuItem<String>(
                      value: dia,
                      child: Text(dia),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _dia = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Selección de horario
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hora de inicio:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _horaInicio,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(alwaysUse24HourFormat: false),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() {
                              _horaInicio = time;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTimeOfDay(_horaInicio)),
                              const Icon(Icons.access_time),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hora de fin:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _horaFin,
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(
                                  context,
                                ).copyWith(alwaysUse24HourFormat: false),
                                child: child!,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() {
                              _horaFin = time;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTimeOfDay(_horaFin)),
                              const Icon(Icons.access_time),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Validar que hora fin sea mayor que hora inicio
                    final inicioMinutos =
                        _horaInicio.hour * 60 + _horaInicio.minute;
                    final finMinutos = _horaFin.hour * 60 + _horaFin.minute;

                    if (finMinutos <= inicioMinutos) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La hora de fin debe ser posterior a la hora de inicio',
                          ),
                        ),
                      );
                      return;
                    }

                    final horario = Horario(
                      id: widget.horario?.id ?? '',
                      hermanoId: _hermanoId,
                      territorioId: _territorioId,
                      dia: _dia,
                      horaInicio: _horaInicio,
                      horaFin: _horaFin,
                    );

                    widget.onSubmit(horario);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
