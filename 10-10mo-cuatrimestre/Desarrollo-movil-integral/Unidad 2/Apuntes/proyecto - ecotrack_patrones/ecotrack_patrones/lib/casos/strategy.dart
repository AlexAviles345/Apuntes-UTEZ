import 'package:flutter/material.dart';

abstract class ReglaTope {
  String get nombre;
  String get unidad;
  bool acepta(double valor);
}

class TopeAgua implements ReglaTope {
  @override
  String get nombre => 'Agua';
  @override
  String get unidad => 'L';
  @override
  bool acepta(double valor) => valor > 0 && valor <= 10000;
}

class TopeLuz implements ReglaTope {
  @override
  String get nombre => 'Luz';
  @override
  String get unidad => 'kWh';
  @override
  bool acepta(double valor) => valor > 0 && valor <= 500;
}

class ValidadorLectura {
  ValidadorLectura(this.regla);

  final ReglaTope regla;

  String resultado(double valor) {
    if (regla.acepta(valor)) {
      return 'aceptada';
    }
    return 'rechazada';
  }
}

class PantallaTope extends StatefulWidget {
  const PantallaTope({super.key});

  @override
  State<PantallaTope> createState() => _PantallaTopeState();
}

class _PantallaTopeState extends State<PantallaTope> {
  final _reglas = <ReglaTope>[TopeAgua(), TopeLuz()];
  late ReglaTope _regla = _reglas.first;
  double _valor = 800;

  @override
  Widget build(BuildContext context) {
    final resultado = ValidadorLectura(_regla).resultado(_valor);
    return Scaffold(
      appBar: AppBar(title: const Text('Tope')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<ReglaTope>(
            segments: [
              for (final r in _reglas)
                ButtonSegment(value: r, label: Text(r.nombre)),
            ],
            selected: {_regla},
            onSelectionChanged: (s) => setState(() => _regla = s.first),
          ),
          const SizedBox(height: 16),
          Text('Lectura: ${_valor.toStringAsFixed(0)} ${_regla.unidad}'),
          Slider(
            value: _valor,
            max: 1200,
            onChanged: (v) => setState(() => _valor = v),
          ),
          Text(
            'ValidadorLectura(${_regla.runtimeType}) → $resultado',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Text(
            'Prueba 800: agua la acepta, luz la rechaza. '
            'ValidadorLectura es la misma clase en los dos casos.',
          ),
        ],
      ),
    );
  }
}
