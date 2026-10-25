import 'package:flutter/material.dart';

import '../dominio/consumo.dart';
import 'registro_view_model.dart';

/// Vista: conserva los widgets y delega las acciones al ViewModel recibido.
/// Esta página recibe la propiedad del ViewModel y lo libera al destruirse.
class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key, required this.viewModel});

  final RegistroViewModel viewModel;

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  RegistroViewModel get _vm => widget.viewModel;
  final _litros = TextEditingController();

  @override
  void didUpdateWidget(covariant RegistroPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.dispose();
    }
  }

  @override
  void dispose() {
    _litros.dispose();
    _vm.dispose();
    super.dispose();
  }

  /// Solo la vista limpia el campo y presenta la confirmación de guardado.
  Future<void> _guardar() async {
    final guardado = await _vm.guardar(_litros.text);
    if (!mounted || !guardado) return;
    _litros.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Consumo guardado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EcoTrack — Registro')),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _vm.laboratorio,
                decoration: const InputDecoration(labelText: 'Laboratorio'),
                items: [
                  for (final lab in laboratoriosUtez)
                    DropdownMenuItem(value: lab, child: Text(lab)),
                ],
                onChanged: (lab) => _vm.cambiarLaboratorio(lab!),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('campoLitros'),
                controller: _litros,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Litros',
                  errorText: _vm.error,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _vm.cargando ? null : _guardar,
                icon: _vm.cargando
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
              const Divider(height: 32),
              Text(
                'Historial de ${_vm.laboratorio} · ${_vm.totalLitros.toStringAsFixed(1)} L',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Expanded(
                child: _vm.historial.isEmpty
                    ? const Center(child: Text('Sin consumos todavía'))
                    : ListView(
                        children: [
                          for (final c in _vm.historial.reversed)
                            ListTile(
                              leading: const Icon(Icons.water_drop),
                              title: Text('${c.litros} L'),
                              subtitle: Text(
                                '${c.fecha.hour}:'
                                '${c.fecha.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
