import 'package:flutter/material.dart';
import 'package:app_p_publica/models/hermano.dart';
import 'package:app_p_publica/services/firebase_service.dart';
import 'package:app_p_publica/widgets/loading_indicator.dart';
import 'package:app_p_publica/widgets/empty_state.dart';

class HermanosScreen extends StatefulWidget {
  const HermanosScreen({super.key});

  @override
  State<HermanosScreen> createState() => _HermanosScreenState();
}

class _HermanosScreenState extends State<HermanosScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Hermano> _hermanos = [];
  List<Hermano> _hermanosFiltrados = [];
  bool _isLoading = true;
  String _busqueda = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHermanos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHermanos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hermanos = await _firebaseService.getHermanos();
      setState(() {
        _hermanos = hermanos;
        _hermanosFiltrados = hermanos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar hermanos: $e');
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

  void _filtrarHermanos(String texto) {
    setState(() {
      _busqueda = texto;
      if (texto.isEmpty) {
        _hermanosFiltrados = _hermanos;
      } else {
        _hermanosFiltrados =
            _hermanos
                .where(
                  (h) =>
                      h.nombre.toLowerCase().contains(texto.toLowerCase()) ||
                      (h.identificador != null &&
                          h.identificador!.toLowerCase().contains(
                            texto.toLowerCase(),
                          )),
                )
                .toList();
      }
    });
  }

  Future<bool> _verificarNombreDuplicado(
    String nombre,
    String? identificador,
    String? hermanoIdActual,
  ) async {
    try {
      // Obtener todos los hermanos para verificar duplicados
      final hermanos = await _firebaseService.getHermanos();

      // Si estamos editando un hermano existente, excluirlo de la verificación
      if (hermanoIdActual != null) {
        hermanos.removeWhere((h) => h.id == hermanoIdActual);
      }

      // Si se proporciona un identificador, el nombre puede repetirse
      if (identificador != null && identificador.isNotEmpty) {
        // Verificar si ya existe la combinación exacta de nombre+identificador
        final duplicadoExacto = hermanos.any(
          (h) =>
              h.nombre.toLowerCase() == nombre.toLowerCase() &&
              h.identificador?.toLowerCase() == identificador.toLowerCase(),
        );

        if (duplicadoExacto) {
          // Mostrar advertencia de duplicado exacto con el mismo identificador
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Combinación duplicada'),
                  content: Text(
                    'Ya existe un hermano/a con el nombre "$nombre" y el identificador "$identificador". Por favor use un identificador diferente.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
          );
          return false; // No permitir continuar en caso de duplicado exacto
        }

        return true; // Permitir continuar si el identificador es único para ese nombre
      }

      // Verificar si ya existe un hermano con exactamente el mismo nombre
      final duplicadosExactos =
          hermanos
              .where((h) => h.nombre.toLowerCase() == nombre.toLowerCase())
              .toList();

      // Si hay duplicados exactos, mostrar diálogo
      if (duplicadosExactos.isNotEmpty) {
        return await _mostrarDialogoDuplicado(nombre, duplicadosExactos);
      }

      // Verificar si existe un hermano con un nombre similar (mismas palabras iniciales)
      final nombrePalabras = nombre.toLowerCase().split(' ');

      // Si el nombre tiene al menos dos palabras, verificar coincidencias parciales
      if (nombrePalabras.length > 1) {
        final nombresParciales =
            hermanos.where((h) {
              final hPalabras = h.nombre.toLowerCase().split(' ');
              // Verificar si las primeras palabras coinciden
              if (hPalabras.length < 2) return false;
              return hPalabras[0] == nombrePalabras[0] &&
                  hPalabras[1] == nombrePalabras[1];
            }).toList();

        if (nombresParciales.isNotEmpty) {
          return await _mostrarDialogoSimilar(nombre, nombresParciales);
        }
      }

      return true; // No hay duplicados, se puede proceder
    } catch (e) {
      print('Error al verificar duplicados: $e');
      return true; // En caso de error, permitir continuar
    }
  }

  Future<bool> _mostrarDialogoDuplicado(
    String nombre,
    List<Hermano> duplicados,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Nombre duplicado'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ya existe${duplicados.length > 1 ? 'n' : ''} ${duplicados.length} hermano${duplicados.length > 1 ? 's' : ''} con el nombre "$nombre":',
                    ),
                    const SizedBox(height: 10),
                    ...duplicados.map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          h.identificador != null && h.identificador!.isNotEmpty
                              ? '• $nombre (${h.identificador})'
                              : '• $nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Se recomienda añadir un identificador para diferenciarlos.',
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed:
                        () => Navigator.pop(context, false), // No continuar
                    child: const Text('Volver a editar'),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.pop(context, true), // Forzar continuar
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Registrar de todos modos'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<bool> _mostrarDialogoSimilar(
    String nombre,
    List<Hermano> similares,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Nombre similar encontrado'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Existen hermanos con nombres similares a "$nombre":'),
                    const SizedBox(height: 10),
                    ...similares.map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          h.identificador != null && h.identificador!.isNotEmpty
                              ? '• ${h.nombre} (${h.identificador})'
                              : '• ${h.nombre}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '¿Desea agregar algún detalle adicional al nombre o un identificador para diferenciarlos?',
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed:
                        () => Navigator.pop(context, false), // No continuar
                    child: const Text('Volver a editar'),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.pop(context, true), // Forzar continuar
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Registrar de todos modos'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<void> _mostrarFormularioHermano(Hermano? hermano) async {
    final esEdicion = hermano != null;
    final _nombreController = TextEditingController(
      text: esEdicion ? hermano.nombre : '',
    );
    final _identificadorController = TextEditingController(
      text:
          esEdicion && hermano.identificador != null
              ? hermano.identificador
              : '',
    );
    final _notasController = TextEditingController(
      text: esEdicion && hermano.notas != null ? hermano.notas : '',
    );
    bool _activo = esEdicion ? hermano.activo : true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
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
                          esEdicion ? 'Editar Hermano' : 'Nuevo Hermano',
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
                        labelText: 'Nombre completo',
                        hintText: 'Ingrese el nombre del hermano',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),

                    // Campo identificador (opcional)
                    TextField(
                      controller: _identificadorController,
                      decoration: InputDecoration(
                        labelText: 'Identificador (opcional)',
                        hintText: 'Ej: "de González", "Senior", "Barrio Norte"',
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Utilice este campo para distinguir personas con el mismo nombre',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo de notas (opcional)
                    TextField(
                      controller: _notasController,
                      decoration: InputDecoration(
                        labelText: 'Notas (opcional)',
                        hintText: 'Información adicional sobre el hermano',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),

                    // Estado activo/inactivo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline),
                          const SizedBox(width: 16),
                          const Text(
                            'Estado:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _activo,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setState(() {
                                _activo = value;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _activo ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              color: _activo ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

                              final identificador =
                                  _identificadorController.text.trim();
                              final notas = _notasController.text.trim();

                              // Verificar si hay duplicados
                              final permitirContinuar =
                                  await _verificarNombreDuplicado(
                                    nombre,
                                    identificador.isEmpty
                                        ? null
                                        : identificador,
                                    esEdicion ? hermano.id : null,
                                  );

                              if (!permitirContinuar) {
                                return; // No continuar con el guardado
                              }

                              try {
                                if (esEdicion) {
                                  final hermanoActualizado = Hermano(
                                    id: hermano.id,
                                    nombre: nombre,
                                    activo: _activo,
                                    identificador:
                                        identificador.isEmpty
                                            ? null
                                            : identificador,
                                    notas: notas.isEmpty ? null : notas,
                                  );
                                  await _firebaseService.updateHermano(
                                    hermanoActualizado,
                                  );
                                } else {
                                  final nuevoHermano = Hermano(
                                    id: '',
                                    nombre: nombre,
                                    activo: _activo,
                                    identificador:
                                        identificador.isEmpty
                                            ? null
                                            : identificador,
                                    notas: notas.isEmpty ? null : notas,
                                  );
                                  await _firebaseService.addHermano(
                                    nuevoHermano,
                                  );
                                }

                                if (mounted) {
                                  Navigator.pop(context);
                                  _loadHermanos();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        esEdicion
                                            ? 'Hermano actualizado correctamente'
                                            : 'Hermano añadido correctamente',
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
          ),
    );
  }

  Future<void> _confirmarEliminar(Hermano hermano) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Está seguro de eliminar a ${hermano.nombreCompleto}? Esta acción eliminará también todos sus horarios asociados.',
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
        await _firebaseService.deleteHermano(hermano.id);
        if (mounted) {
          _loadHermanos();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hermano eliminado correctamente'),
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
      return const LoadingIndicator(message: 'Cargando hermanos...');
    }

    return Scaffold(
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar hermanos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _busqueda.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filtrarHermanos('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filtrarHermanos,
            ),
          ),

          // Contador de hermanos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  _busqueda.isEmpty
                      ? 'Total: ${_hermanos.length} hermanos'
                      : 'Resultados: ${_hermanosFiltrados.length} hermanos',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Filtro de estado (activo/inactivo)
                PopupMenuButton<String>(
                  icon: Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: 4),
                      Text(
                        'Filtrar',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  onSelected: (value) {
                    if (value == 'todos') {
                      setState(() {
                        _hermanosFiltrados = _hermanos;
                      });
                    } else if (value == 'activos') {
                      setState(() {
                        _hermanosFiltrados =
                            _hermanos.where((h) => h.activo).toList();
                      });
                    } else if (value == 'inactivos') {
                      setState(() {
                        _hermanosFiltrados =
                            _hermanos.where((h) => !h.activo).toList();
                      });
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'todos',
                          child: Text('Todos'),
                        ),
                        const PopupMenuItem(
                          value: 'activos',
                          child: Text('Activos'),
                        ),
                        const PopupMenuItem(
                          value: 'inactivos',
                          child: Text('Inactivos'),
                        ),
                      ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Lista de hermanos
          Expanded(
            child:
                _hermanosFiltrados.isEmpty
                    ? EmptyState(
                      message:
                          _busqueda.isNotEmpty
                              ? 'No se encontraron hermanos con "$_busqueda"'
                              : 'No hay hermanos registrados. Pulse el botón + para añadir uno.',
                      icon: Icons.people,
                      actionLabel: 'Añadir hermano',
                      onAction: () => _mostrarFormularioHermano(null),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadHermanos,
                      child: ListView.separated(
                        itemCount: _hermanosFiltrados.length,
                        separatorBuilder:
                            (context, index) => const Divider(height: 1),
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (context, index) {
                          final hermano = _hermanosFiltrados[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  hermano.activo ? Colors.blue : Colors.grey,
                              child: Text(
                                hermano.nombre.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              hermano.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hermano.identificador != null &&
                                    hermano.identificador!.isNotEmpty)
                                  Text(
                                    hermano.identificador!,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            hermano.activo
                                                ? Colors.green[50]
                                                : Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              hermano.activo
                                                  ? Colors.green
                                                  : Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        hermano.activo ? 'Activo' : 'Inactivo',
                                        style: TextStyle(
                                          color:
                                              hermano.activo
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (hermano.notas != null &&
                                        hermano.notas!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed:
                                      () => _mostrarFormularioHermano(hermano),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmarEliminar(hermano),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                            onTap: () => _mostrarFormularioHermano(hermano),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioHermano(null),
        tooltip: 'Añadir hermano',
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
