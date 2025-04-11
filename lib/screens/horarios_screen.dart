import 'package:flutter/material.dart';
import 'package:app_p_publica/models/hermano.dart';
import 'package:app_p_publica/models/territorio.dart';
import 'package:app_p_publica/models/horario.dart';
import 'package:app_p_publica/services/firebase_service.dart';
import 'package:app_p_publica/widgets/loading_indicator.dart';
import 'package:app_p_publica/widgets/empty_state.dart';
import 'package:intl/intl.dart';

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  List<Hermano> _hermanos = [];
  List<Territorio> _territorios = [];
  Map<String, List<Horario>> _horariosPorHermano = {};
  bool _isLoading = true;

  // Para filtrar la vista
  String? _filtroHermanoId;
  String? _filtroTerritorioId;
  String? _filtroDia;

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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar datos
      final hermanos = await _firebaseService.getHermanos();
      final territorios = await _firebaseService.getTerritorios();
      final horarios = await _firebaseService.getHorarios();

      // Agrupar horarios por hermano
      final Map<String, List<Horario>> horariosPorHermano = {};

      for (var hermano in hermanos) {
        horariosPorHermano[hermano.id] = [];
      }

      for (var horario in horarios) {
        if (horariosPorHermano.containsKey(horario.hermanoId)) {
          horariosPorHermano[horario.hermanoId]!.add(horario);
        }
      }

      setState(() {
        _hermanos = hermanos;
        _territorios = territorios;
        _horariosPorHermano = horariosPorHermano;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.Hm();
    return format.format(dt);
  }

  String _getNombreTerritorio(String territorioId) {
    final territorio = _territorios.firstWhere(
      (t) => t.id == territorioId,
      orElse: () => Territorio(id: '', nombre: 'Desconocido', descripcion: ''),
    );
    return territorio.nombre;
  }

  String _getNombreCompletoHermano(String hermanoId) {
    final hermano = _hermanos.firstWhere(
      (h) => h.id == hermanoId,
      orElse: () => Hermano(id: '', nombre: 'Desconocido', activo: true),
    );
    return hermano.nombreCompleto;
  }

  Future<void> _mostrarDialogoFiltros() async {
    String? hermanoId = _filtroHermanoId;
    String? territorioId = _filtroTerritorioId;
    String? dia = _filtroDia;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Filtrar Horarios'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(labelText: 'Hermano'),
                        value: hermanoId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos los hermanos'),
                          ),
                          ..._hermanos
                              .map(
                                (hermano) => DropdownMenuItem(
                                  value: hermano.id,
                                  child: Text(hermano.nombreCompleto),
                                ),
                              )
                              .toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            hermanoId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(
                          labelText: 'Territorio',
                        ),
                        value: territorioId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos los territorios'),
                          ),
                          ..._territorios
                              .map(
                                (territorio) => DropdownMenuItem(
                                  value: territorio.id,
                                  child: Text(territorio.nombre),
                                ),
                              )
                              .toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            territorioId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(labelText: 'Día'),
                        value: dia,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos los días'),
                          ),
                          ..._diasSemana
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            dia = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      this.setState(() {
                        _filtroHermanoId = hermanoId;
                        _filtroTerritorioId = territorioId;
                        _filtroDia = dia;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Aplicar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroHermanoId = null;
      _filtroTerritorioId = null;
      _filtroDia = null;
    });
  }

  Future<void> _mostrarDialogoNuevoHorario() async {
    // Redirigir a la pantalla de selección de hermano primero
    if (_hermanos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay hermanos registrados')),
      );
      return;
    }

    if (_territorios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay territorios registrados')),
      );
      return;
    }

    // Solo mostrar hermanos activos
    final hermanosActivos = _hermanos.where((h) => h.activo).toList();

    if (hermanosActivos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay hermanos activos registrados')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccionar Hermano',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 300,
                  child: ListView.builder(
                    itemCount: hermanosActivos.length,
                    itemBuilder: (context, index) {
                      final hermano = hermanosActivos[index];
                      return ListTile(
                        title: Text(hermano.nombreCompleto),
                        leading: CircleAvatar(
                          child: Text(hermano.nombre.substring(0, 1)),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _mostrarDialogoDetalleHorario(hermano);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Future<void> _mostrarDialogoDetalleHorario(
    Hermano hermano, [
    Horario? horario,
  ]) async {
    String territorioId =
        horario?.territorioId ??
        (_territorios.isNotEmpty ? _territorios[0].id : '');
    String dia = horario?.dia ?? 'Lunes';
    TimeOfDay horaInicio =
        horario?.horaInicio ?? const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay horaFin =
        horario?.horaFin ?? const TimeOfDay(hour: 10, minute: 0);
    final esEdicion = horario != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    esEdicion
                        ? 'Editar Horario'
                        : 'Nuevo Horario para ${hermano.nombreCompleto}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Territorio
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Territorio',
                      border: OutlineInputBorder(),
                    ),
                    value: territorioId,
                    items:
                        _territorios
                            .map(
                              (territorio) => DropdownMenuItem(
                                value: territorio.id,
                                child: Text(territorio.nombre),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          territorioId = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Día
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Día',
                      border: OutlineInputBorder(),
                    ),
                    value: dia,
                    items:
                        _diasSemana
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          dia = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Horas
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hora de inicio'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: horaInicio,
                                );
                                if (time != null) {
                                  setState(() {
                                    horaInicio = time;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatTimeOfDay(horaInicio)),
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
                            const Text('Hora de fin'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: horaFin,
                                );
                                if (time != null) {
                                  setState(() {
                                    horaFin = time;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatTimeOfDay(horaFin)),
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
                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          // Validar que hora fin sea mayor que hora inicio
                          final inicioMinutos =
                              horaInicio.hour * 60 + horaInicio.minute;
                          final finMinutos = horaFin.hour * 60 + horaFin.minute;

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

                          try {
                            final nuevoHorario = Horario(
                              id: horario?.id ?? '',
                              hermanoId: hermano.id,
                              territorioId: territorioId,
                              dia: dia,
                              horaInicio: horaInicio,
                              horaFin: horaFin,
                            );

                            if (esEdicion) {
                              await _firebaseService.updateHorario(
                                nuevoHorario,
                              );
                            } else {
                              await _firebaseService.addHorario(nuevoHorario);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              _loadData(); // Recargar datos

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    esEdicion
                                        ? 'Horario actualizado correctamente'
                                        : 'Horario creado correctamente',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: Text(esEdicion ? 'Actualizar' : 'Guardar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarEliminar(Horario horario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text('¿Está seguro de eliminar este horario?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        await _firebaseService.deleteHorario(horario.id);
        if (mounted) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Horario eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Cargando horarios...');
    }

    // Filtrar horarios
    List<Horario> horariosParaMostrar = [];

    if (_filtroHermanoId != null) {
      // Mostrar horarios de un hermano específico
      horariosParaMostrar = _horariosPorHermano[_filtroHermanoId!] ?? [];
    } else {
      // Mostrar todos los horarios
      for (var horariosHermano in _horariosPorHermano.values) {
        horariosParaMostrar.addAll(horariosHermano);
      }
    }

    // Aplicar filtro de territorio
    if (_filtroTerritorioId != null) {
      horariosParaMostrar =
          horariosParaMostrar
              .where((h) => h.territorioId == _filtroTerritorioId)
              .toList();
    }

    // Aplicar filtro de día
    if (_filtroDia != null) {
      horariosParaMostrar =
          horariosParaMostrar.where((h) => h.dia == _filtroDia).toList();
    }

    // Ordenar por hermano, día y hora de inicio
    horariosParaMostrar.sort((a, b) {
      // Buscar nombres de hermanos
      final nombreHermanoA = _getNombreCompletoHermano(a.hermanoId);
      final nombreHermanoB = _getNombreCompletoHermano(b.hermanoId);

      // Comparar por nombre de hermano
      int nombreComp = nombreHermanoA.compareTo(nombreHermanoB);
      if (nombreComp != 0) return nombreComp;

      // Orden de días
      final diasOrden = {
        'Lunes': 0,
        'Martes': 1,
        'Miércoles': 2,
        'Jueves': 3,
        'Viernes': 4,
        'Sábado': 5,
        'Domingo': 6,
      };

      int diaComp = (diasOrden[a.dia] ?? 0).compareTo(diasOrden[b.dia] ?? 0);
      if (diaComp != 0) return diaComp;

      // Comparar por hora de inicio
      final inicioA = a.horaInicio.hour * 60 + a.horaInicio.minute;
      final inicioB = b.horaInicio.hour * 60 + b.horaInicio.minute;
      return inicioA.compareTo(inicioB);
    });

    // Obtener listado de hermanos únicos con horarios
    Map<String, String> hermanosConHorarios = {};
    for (var horario in horariosParaMostrar) {
      final nombreCompleto = _getNombreCompletoHermano(horario.hermanoId);
      hermanosConHorarios[horario.hermanoId] = nombreCompleto;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios de Predicación'),
        actions: [
          // Botón de filtros
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarDialogoFiltros,
            tooltip: 'Filtrar horarios',
          ),

          // Si hay filtros activos, mostrar botón para limpiar
          if (_filtroHermanoId != null ||
              _filtroTerritorioId != null ||
              _filtroDia != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _limpiarFiltros,
              tooltip: 'Limpiar filtros',
            ),
        ],
      ),
      body:
          horariosParaMostrar.isEmpty
              ? EmptyState(
                message:
                    'No hay horarios registrados. Pulse el botón + para añadir uno.',
                icon: Icons.schedule,
                actionLabel: 'Añadir horario',
                onAction: _mostrarDialogoNuevoHorario,
              )
              : ListView.builder(
                itemCount: hermanosConHorarios.length,
                itemBuilder: (context, index) {
                  final hermanoId = hermanosConHorarios.keys.elementAt(index);
                  final hermanoNombre = hermanosConHorarios[hermanoId]!;

                  // Filtrar horarios de este hermano
                  final horariosHermano =
                      horariosParaMostrar
                          .where((h) => h.hermanoId == hermanoId)
                          .toList();

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: ExpansionTile(
                      title: Text(
                        hermanoNombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      leading: CircleAvatar(
                        child: Text(hermanoNombre.substring(0, 1)),
                      ),
                      children:
                          horariosHermano.map((horario) {
                            // Obtener datos para mostrar
                            final territorioNombre = _getNombreTerritorio(
                              horario.territorioId,
                            );
                            final horaInicio = _formatTimeOfDay(
                              horario.horaInicio,
                            );
                            final horaFin = _formatTimeOfDay(horario.horaFin);

                            return ListTile(
                              title: Text(territorioNombre),
                              subtitle: Text(
                                '${horario.dia} - $horaInicio a $horaFin',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      final hermano = _hermanos.firstWhere(
                                        (h) => h.id == horario.hermanoId,
                                        orElse:
                                            () => Hermano(
                                              id: '',
                                              nombre: '',
                                              activo: true,
                                            ),
                                      );
                                      _mostrarDialogoDetalleHorario(
                                        hermano,
                                        horario,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () => _confirmarEliminar(horario),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevoHorario,
        tooltip: 'Añadir horario',
        child: const Icon(Icons.add),
      ),
    );
  }
}
