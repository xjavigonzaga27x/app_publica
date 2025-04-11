import 'package:flutter/material.dart';
import 'package:app_p_publica/models/territorio.dart';
import 'package:app_p_publica/models/horario.dart';
import 'package:app_p_publica/services/firebase_service.dart';
import 'package:app_p_publica/widgets/loading_indicator.dart';
import 'package:app_p_publica/widgets/empty_state.dart';
import 'package:app_p_publica/widgets/territorio_card.dart';
import 'package:intl/intl.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Territorio> _territorios = [];
  Map<String, List<Horario>> _horariosPorTerritorio = {};
  bool _isLoading = true;
  String? _territorioSeleccionado;

  @override
  void initState() {
    super.initState();
    _loadTerritorios();
  }

  Future<void> _loadTerritorios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final territorios = await _firebaseService.getTerritorios();
      setState(() {
        _territorios = territorios;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar territorios: $e');
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

  Future<void> _loadHorariosTerritorio(String territorioId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final horarios = await _firebaseService.getHorariosByTerritorio(
        territorioId,
      );

      // Agrupar horarios por día
      final Map<String, List<Horario>> horariosPorDia = {};
      for (var horario in horarios) {
        if (!horariosPorDia.containsKey(horario.dia)) {
          horariosPorDia[horario.dia] = [];
        }
        horariosPorDia[horario.dia]!.add(horario);
      }

      setState(() {
        _horariosPorTerritorio = horariosPorDia;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar horarios: $e');
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

  // Ordenar días de la semana
  int _ordenDia(String dia) {
    const dias = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo",
    ];
    return dias.indexOf(dia);
  }

  // Ordenar lista
  List<T> _ordenarLista<T>(List<T> lista, int Function(T a, T b) comparador) {
    final listaOrdenada = List<T>.from(lista);
    listaOrdenada.sort(comparador);
    return listaOrdenada;
  }

  Widget _buildHorarioCard(Horario horario) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatTimeOfDay(horario.horaInicio)} - ${_formatTimeOfDay(horario.horaFin)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Hermano/a: ${horario.hermanoNombre ?? "Desconocido"}'),
          ],
        ),
      ),
    );
  }

  Future<void> _exportarHorarios() async {
    // Esta función sería para implementar la exportación de horarios,
    // por ejemplo a PDF o compartir como texto
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de exportación pendiente de implementar'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Cargando datos...');
    }

    if (_territorios.isEmpty) {
      return const EmptyState(
        message: 'No hay territorios registrados para generar reportes.',
        icon: Icons.map,
      );
    }

    if (_territorioSeleccionado == null) {
      // Pantalla de selección de territorio
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: _loadTerritorios,
          child: ListView.builder(
            itemCount: _territorios.length,
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemBuilder: (context, index) {
              final territorio = _territorios[index];
              return TerritorioCard(
                territorio: territorio,
                onTap: () {
                  setState(() {
                    _territorioSeleccionado = territorio.id;
                  });
                  _loadHorariosTerritorio(territorio.id);
                },
                onEdit: () {}, // No se requiere para reportes
                onDelete: () {}, // No se requiere para reportes
              );
            },
          ),
        ),
      );
    } else {
      // Pantalla de detalle del territorio seleccionado
      final nombreTerritorio =
          _territorios
              .firstWhere((t) => t.id == _territorioSeleccionado)
              .nombre;

      return Scaffold(
        appBar: AppBar(
          title: Text('Horarios: $nombreTerritorio'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _territorioSeleccionado = null;
              });
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _exportarHorarios,
              tooltip: 'Exportar horarios',
            ),
          ],
        ),
        body:
            _horariosPorTerritorio.isEmpty
                ? const EmptyState(
                  message: 'No hay horarios registrados para este territorio.',
                  icon: Icons.schedule,
                )
                : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children:
                      _ordenarLista(
                        _horariosPorTerritorio.keys.toList(),
                        (a, b) => _ordenDia(a).compareTo(_ordenDia(b)),
                      ).map((dia) {
                        final horariosDelDia = _ordenarLista(
                          _horariosPorTerritorio[dia]!,
                          (a, b) {
                            final aMinutos =
                                a.horaInicio.hour * 60 + a.horaInicio.minute;
                            final bMinutos =
                                b.horaInicio.hour * 60 + b.horaInicio.minute;
                            return aMinutos.compareTo(bMinutos);
                          },
                        );

                        return ExpansionTile(
                          title: Text(
                            dia,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          initiallyExpanded: true,
                          children:
                              horariosDelDia
                                  .map((horario) => _buildHorarioCard(horario))
                                  .toList(),
                        );
                      }).toList(),
                ),
      );
    }
  }
}
