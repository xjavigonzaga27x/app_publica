import 'package:flutter/material.dart';
import 'package:app_p_publica/models/territorio.dart';
import 'package:app_p_publica/services/firebase_service.dart';
import 'package:app_p_publica/widgets/loading_indicator.dart';
import 'package:app_p_publica/widgets/empty_state.dart';

class TerritoriosScreen extends StatefulWidget {
  const TerritoriosScreen({super.key});

  @override
  State<TerritoriosScreen> createState() => _TerritoriosScreenState();
}

class _TerritoriosScreenState extends State<TerritoriosScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Territorio> _territorios = [];
  List<Territorio> _territoriosFiltrados = [];
  bool _isLoading = true;
  String _busqueda = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTerritorios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTerritorios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final territorios = await _firebaseService.getTerritorios();
      setState(() {
        _territorios = territorios;
        _territoriosFiltrados = territorios;
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

  void _filtrarTerritorios(String texto) {
    setState(() {
      _busqueda = texto;
      if (texto.isEmpty) {
        _territoriosFiltrados = _territorios;
      } else {
        _territoriosFiltrados =
            _territorios.where((t) {
              return t.nombre.toLowerCase().contains(texto.toLowerCase()) ||
                  t.descripcion.toLowerCase().contains(texto.toLowerCase());
            }).toList();
      }
    });
  }

  Future<void> _mostrarFormularioTerritorio(Territorio? territorio) async {
    final esEdicion = territorio != null;
    final _nombreController = TextEditingController(
      text: esEdicion ? territorio.nombre : '',
    );
    final _descripcionController = TextEditingController(
      text: esEdicion ? territorio.descripcion : '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    esEdicion ? 'Editar Territorio' : 'Nuevo Territorio',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 20),

              // Campo Nombre
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del territorio',
                  hintText: 'Ingrese el nombre del territorio',
                  prefixIcon: const Icon(Icons.map),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),

              // Campo Descripción
              TextField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ingrese una descripción o detalles del territorio',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 30),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final nombre = _nombreController.text.trim();
                        if (nombre.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('El nombre es obligatorio'),
                            ),
                          );
                          return;
                        }

                        try {
                          if (esEdicion) {
                            final territorioActualizado = Territorio(
                              id: territorio.id,
                              nombre: nombre,
                              descripcion: _descripcionController.text.trim(),
                            );
                            await _firebaseService.updateTerritorio(
                              territorioActualizado,
                            );
                          } else {
                            final nuevoTerritorio = Territorio(
                              id: '',
                              nombre: nombre,
                              descripcion: _descripcionController.text.trim(),
                            );
                            await _firebaseService.addTerritorio(
                              nuevoTerritorio,
                            );
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            _loadTerritorios();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  esEdicion
                                      ? 'Territorio actualizado correctamente'
                                      : 'Territorio añadido correctamente',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      },
                      icon: Icon(esEdicion ? Icons.save : Icons.add),
                      label: Text(esEdicion ? 'Actualizar' : 'Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmarEliminar(Territorio territorio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Está seguro de eliminar "${territorio.nombre}"? Esta acción eliminará también todos los horarios asociados a este territorio.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        await _firebaseService.deleteTerritorio(territorio.id);
        if (mounted) {
          _loadTerritorios();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Territorio eliminado correctamente'),
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
      return const LoadingIndicator(message: 'Cargando territorios...');
    }

    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar territorios...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _busqueda.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filtrarTerritorios('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filtrarTerritorios,
            ),
          ),

          // Contador de territorios
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  _busqueda.isEmpty
                      ? 'Total: ${_territorios.length} territorios'
                      : 'Resultados: ${_territoriosFiltrados.length} territorios',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Lista de territorios
          Expanded(
            child:
                _territoriosFiltrados.isEmpty
                    ? EmptyState(
                      message:
                          _busqueda.isNotEmpty
                              ? 'No se encontraron territorios con "$_busqueda"'
                              : 'No hay territorios registrados. Pulse el botón + para añadir uno.',
                      icon: Icons.map,
                      actionLabel: 'Añadir territorio',
                      onAction: () => _mostrarFormularioTerritorio(null),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadTerritorios,
                      child: ListView.builder(
                        itemCount: _territoriosFiltrados.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, index) {
                          final territorio = _territoriosFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap:
                                  () =>
                                      _mostrarFormularioTerritorio(territorio),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                territorio.nombre,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (territorio
                                                  .descripcion
                                                  .isNotEmpty)
                                                Text(
                                                  territorio.descripcion,
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              onPressed:
                                                  () =>
                                                      _mostrarFormularioTerritorio(
                                                        territorio,
                                                      ),
                                              tooltip: 'Editar',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed:
                                                  () => _confirmarEliminar(
                                                    territorio,
                                                  ),
                                              tooltip: 'Eliminar',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioTerritorio(null),
        tooltip: 'Añadir territorio',
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
