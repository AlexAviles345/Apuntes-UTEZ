// Etapa 4 — widgets tontos: reciben datos y callbacks, no saben qué gestor hay arriba.

import 'package:flutter/material.dart';

import '../dominio/consumo.dart';

class FormularioRegistro extends StatefulWidget {
  const FormularioRegistro({
    super.key,
    required this.alGuardar,
    required this.error,
    required this.guardando,
  });

  final Future<bool> Function(String laboratorio, String litros) alGuardar;
  final String? error;
  final bool guardando;

  @override
  State<FormularioRegistro> createState() => _FormularioRegistroState();
}

class _FormularioRegistroState extends State<FormularioRegistro> {
  // Estado efímero: solo le importa a este formulario.
  String _laboratorio = laboratoriosUtez.first;
  final TextEditingController _litros = TextEditingController();

  @override
  void dispose() {
    _litros.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final guardado = await widget.alGuardar(_laboratorio, _litros.text);
    // Después del await el widget pudo desmontarse.
    if (!guardado || !mounted) return;
    _litros.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Consumo guardado')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _laboratorio,
          decoration: const InputDecoration(labelText: 'Laboratorio'),
          items: [
            for (final lab in laboratoriosUtez)
              DropdownMenuItem(value: lab, child: Text(lab)),
          ],
          onChanged: (lab) {
            if (lab != null) setState(() => _laboratorio = lab);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('litros'),
          controller: _litros,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Litros',
            errorText: widget.error,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: widget.guardando ? null : _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class ListaHistorial extends StatelessWidget {
  const ListaHistorial({super.key, required this.consumos, required this.total});

  final List<Consumo> consumos;
  final double total;

  @override
  Widget build(BuildContext context) {
    if (consumos.isEmpty) {
      return const Center(child: Text('Sin consumos'));
    }
    return ListView(
      children: [
        ListTile(
          title: Text(
            'Total: ${total.toStringAsFixed(1)} L',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final consumo in consumos)
          ListTile(
            leading: const Icon(Icons.water_drop_outlined),
            title: Text(consumo.laboratorio),
            trailing: Text('${consumo.litros.toStringAsFixed(1)} L'),
          ),
      ],
    );
  }
}

class PanelMeta extends StatelessWidget {
  const PanelMeta({
    super.key,
    required this.usado,
    required this.meta,
    required this.avance,
    required this.superada,
    required this.alSubir,
    required this.alBajar,
  });

  final double usado;
  final double meta;
  final double avance;
  final bool superada;
  final VoidCallback alSubir;
  final VoidCallback alBajar;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Usado: ${usado.toStringAsFixed(1)} de ${meta.toStringAsFixed(1)} L',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: avance,
            color: superada ? colores.error : null,
          ),
          const SizedBox(height: 12),
          Text(
            superada ? 'Te pasaste de la meta' : 'Dentro de la meta',
            style: TextStyle(color: superada ? colores.error : null),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                key: const Key('bajarMeta'),
                onPressed: alBajar,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 16),
              IconButton.outlined(
                key: const Key('subirMeta'),
                onPressed: alSubir,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PantallasEcoTrack extends StatefulWidget {
  const PantallasEcoTrack({
    super.key,
    required this.titulo,
    required this.registro,
    required this.historial,
    required this.meta,
  });

  final String titulo;
  final Widget registro;
  final Widget historial;
  final Widget meta;

  @override
  State<PantallasEcoTrack> createState() => _PantallasEcoTrackState();
}

class _PantallasEcoTrackState extends State<PantallasEcoTrack> {
  // Estado efímero: la pestaña activa.
  int _pestana = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      // IndexedStack mantiene montadas las tres pestañas y solo enseña una.
      body: IndexedStack(
        index: _pestana,
        children: [widget.registro, widget.historial, widget.meta],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (i) => setState(() => _pestana = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.edit), label: 'Registro'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Meta'),
        ],
      ),
    );
  }
}
