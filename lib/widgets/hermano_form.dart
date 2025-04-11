import 'package:flutter/material.dart';
import 'package:app_p_publica/models/hermano.dart';

class HermanoForm extends StatefulWidget {
  final Hermano? hermano;
  final Function(Hermano hermano) onSubmit;

  const HermanoForm({super.key, this.hermano, required this.onSubmit});

  @override
  State<HermanoForm> createState() => _HermanoFormState();
}

class _HermanoFormState extends State<HermanoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    if (widget.hermano != null) {
      _nombreController.text = widget.hermano!.nombre;
      _activo = widget.hermano!.activo;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.hermano != null;

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              esEdicion ? 'Editar Hermano' : 'Nuevo Hermano',
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
                hintText: 'Ingrese el nombre completo',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Campo Estado (Activo/Inactivo)
            Row(
              children: [
                const Text(
                  'Estado:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: _activo,
                  onChanged: (value) {
                    setState(() {
                      _activo = value;
                    });
                  },
                ),
                Text(
                  _activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: _activo ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
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
                    if (_formKey.currentState!.validate()) {
                      final hermano = Hermano(
                        id: widget.hermano?.id ?? '',
                        nombre: _nombreController.text.trim(),
                        activo: _activo,
                      );

                      widget.onSubmit(hermano);
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
