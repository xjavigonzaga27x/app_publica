import 'package:flutter/material.dart';
import 'package:app_p_publica/models/territorio.dart';

class TerritorioForm extends StatefulWidget {
  final Territorio? territorio;
  final Function(Territorio territorio) onSubmit;

  const TerritorioForm({super.key, this.territorio, required this.onSubmit});

  @override
  State<TerritorioForm> createState() => _TerritorioFormState();
}

class _TerritorioFormState extends State<TerritorioForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.territorio != null) {
      _nombreController.text = widget.territorio!.nombre;
      _descripcionController.text = widget.territorio!.descripcion;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.territorio != null;

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              esEdicion ? 'Editar Territorio' : 'Nuevo Territorio',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Campo Nombre
            const Text(
              'Nombre:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese el nombre del territorio',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Campo Descripción
            const Text(
              'Descripción (opcional):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingrese una descripción o detalles del territorio',
              ),
              maxLines: 3,
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
                    if (_formKey.currentState!.validate()) {
                      final territorio = Territorio(
                        id: widget.territorio?.id ?? '',
                        nombre: _nombreController.text.trim(),
                        descripcion: _descripcionController.text.trim(),
                      );

                      widget.onSubmit(territorio);
                      Navigator.of(context).pop();
                    }
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
