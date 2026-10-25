import 'package:flutter/material.dart';

class Aviso {
  Aviso(this.texto, {required this.cumplida});

  final String texto;
  final bool cumplida;

  factory Aviso.metaCumplida() {
    return Aviso('Llegaste a la meta semanal de agua', cumplida: true);
  }

  factory Aviso.metaPendiente(double faltan) {
    return Aviso(
      'Faltan ${faltan.toStringAsFixed(1)} L para la meta',
      cumplida: false,
    );
  }

  /// Elige la forma correcta. La pantalla no decide cuál construir.
  factory Aviso.paraMeta({required double ahorrados, required double meta}) {
    if (ahorrados >= meta) return Aviso.metaCumplida();
    return Aviso.metaPendiente(meta - ahorrados);
  }
}

class PantallaAviso extends StatefulWidget {
  const PantallaAviso({super.key});

  @override
  State<PantallaAviso> createState() => _PantallaAvisoState();
}

class _PantallaAvisoState extends State<PantallaAviso> {
  static const meta = 50.0;
  double _ahorrados = 30;

  @override
  Widget build(BuildContext context) {
    final aviso = Aviso.paraMeta(ahorrados: _ahorrados, meta: meta);

    return Scaffold(
      appBar: AppBar(title: const Text('Aviso')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Litros ahorrados esta semana: ${_ahorrados.toStringAsFixed(1)}'
            ' de ${meta.toStringAsFixed(0)}',
          ),
          Slider(
            value: _ahorrados,
            max: 60,
            onChanged: (v) => setState(() => _ahorrados = v),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                aviso.cumplida ? Icons.emoji_events : Icons.hourglass_bottom,
              ),
              title: Text(aviso.texto),
            ),
          ),
        ],
      ),
    );
  }
}
