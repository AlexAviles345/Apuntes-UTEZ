import 'package:flutter/material.dart';

class RegistroConsumo extends ChangeNotifier {
  final List<double> _litros = [];

  List<double> get litros => List.unmodifiable(_litros);

  void guardar(double litros) {
    _litros.add(litros);
    notifyListeners();
  }
}

class PantallaPaneles extends StatefulWidget {
  const PantallaPaneles({super.key});

  @override
  State<PantallaPaneles> createState() => _PantallaPanelesState();
}

class _PantallaPanelesState extends State<PantallaPaneles> {
  final _registro = RegistroConsumo();

  @override
  void dispose() {
    _registro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paneles')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton(
            onPressed: () => _registro.guardar(12.5),
            child: const Text('Guardar 12.5 L'),
          ),
          const SizedBox(height: 16),
          PanelHistorial(registro: _registro),
          PanelMeta(registro: _registro, meta: 50),
        ],
      ),
    );
  }
}

class PanelHistorial extends StatelessWidget {
  const PanelHistorial({super.key, required this.registro});

  final RegistroConsumo registro;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: registro,
      builder: (context, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Historial'),
          subtitle: Text('${registro.litros.length} registros'),
        ),
      ),
    );
  }
}

class PanelMeta extends StatelessWidget {
  const PanelMeta({super.key, required this.registro, required this.meta});

  final RegistroConsumo registro;
  final double meta;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: registro,
      builder: (context, _) {
        final usados = registro.litros.fold<double>(0, (s, l) => s + l);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Meta'),
            subtitle: Text('Quedan ${(meta - usados).toStringAsFixed(1)} L'),
          ),
        );
      },
    );
  }
}
