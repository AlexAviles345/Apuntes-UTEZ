// U1-S01-A04 — Reto "El Impostor": punto de partida
//
//   flutter run -t lib/main_mezclado.dart
//
// Esta app FUNCIONA y hace todo lo que debe hacer EcoTrack:
// validar, guardar en memoria o en la "nube", listar el historial
// por laboratorio y sumar los litros. El problema es que TODO vive
// dentro de un solo State.
//
// Su misión: llevar cada pieza a su capa (dominio, datos, presentación)
// sin cambiar lo que la persona ve. Busquen las marcas MEZCLA 1..6:
// cada una dice qué está mezclado y les da una pista de a dónde va.
//
// Cuando terminen, este archivo puede quedarse como referencia,
// pero la app final debe arrancar con `flutter run` (lib/main.dart).

import 'package:flutter/material.dart';

void main() => runApp(
      MaterialApp(
        title: 'EcoTrack',
        theme: ThemeData(colorSchemeSeed: Colors.green),
        home: const PantallaMezclada(),
      ),
    );

class PantallaMezclada extends StatefulWidget {
  const PantallaMezclada({super.key});

  @override
  State<PantallaMezclada> createState() => _PantallaMezcladaState();
}

class _PantallaMezcladaState extends State<PantallaMezclada> {
  // MEZCLA 5 — La pantalla decide de dónde salen los datos.
  // Para cambiar de lista a nube hay que abrir y editar este widget.
  // Pista: "un solo lugar conoce las implementaciones concretas".
  static const _usarNube = false;

  // MEZCLA 1 — La pantalla es dueña de los datos.
  // La lista en memoria y el "servidor" viven dentro del State;
  // si la pantalla se destruye, los datos se van con ella.
  // Pista: alguien que cumpla un contrato con guardar / listarPorLaboratorio.
  final List<Map<String, Object>> _memoria = [];
  final List<Map<String, Object>> _servidor = [];

  // MEZCLA 2 — No existe un "Consumo": es un Map con llaves escritas a mano.
  // La lista de laboratorios y las reglas (más abajo) solo viven aquí;
  // el historial, la meta semanal u otro formulario tendrían que copiarlas.
  // Pista: "si apago Flutter, ¿esto sigue teniendo sentido?".
  static const _laboratorios = ['Lab Química', 'Lab Redes', 'Lab Física'];
  static const _topeLitros = 10000.0;

  // MEZCLA 6 — El estado de la pantalla y la orquestación viven en el State,
  // junto a los widgets. No se puede probar "guardar" sin dibujar la pantalla.
  // Además, la fecha sale de DateTime.now(): una prueba no puede fijar "hoy".
  // Pista: algo que guarde estado, avise "cambié" y no conozca widgets.
  String _laboratorio = _laboratorios.first;
  bool _cargando = false;
  String? _error;
  List<Map<String, Object>> _historial = [];

  final _litros = TextEditingController();

  @override
  void dispose() {
    _litros.dispose();
    super.dispose();
  }

  Future<void> _cambiarLaboratorio(String nuevo) async {
    setState(() {
      _laboratorio = nuevo;
      _error = null;
    });
    await _recargarHistorial();
  }

  Future<void> _guardar() async {
    final litros = double.tryParse(_litros.text.trim().replaceAll(',', '.'));
    if (litros == null) {
      setState(() => _error = 'Escribe los litros con número');
      return;
    }

    final fecha = DateTime.now();

    // MEZCLA 2 (continúa) — Las reglas del negocio, escritas dentro del botón.
    String? motivo;
    if (_laboratorio.trim().isEmpty) {
      motivo = 'El laboratorio es obligatorio';
    } else if (litros <= 0) {
      motivo = 'Los litros deben ser mayores que cero';
    } else if (litros > _topeLitros) {
      motivo = 'Los litros superan el tope de ${_topeLitros.toStringAsFixed(0)}';
    } else if (fecha.isAfter(DateTime.now())) {
      motivo = 'La fecha no puede ser futura';
    }
    if (motivo != null) {
      setState(() => _error = motivo);
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    if (_usarNube) {
      // MEZCLA 3 — La pantalla finge la red y arma el JSON.
      // La espera de 600 ms y las llaves del mapa son detalles del canal.
      // Pista: un servicio que solo hable JSON, y un repositorio que
      // traduzca entre ese JSON y un Consumo.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _servidor.add({
        'laboratorio': _laboratorio,
        'litros': litros,
        'fecha': fecha.toIso8601String(),
      });
    } else {
      _memoria.add({
        'laboratorio': _laboratorio,
        'litros': litros,
        'fecha': fecha,
      });
    }

    await _recargarHistorial();
    if (!mounted) return;
    _litros.clear();

    // MEZCLA 4 — Este aviso SÍ es de la vista y aquí se queda.
    // La trampa es al separar: si "guardar" en los datos recibe un
    // BuildContext para mostrarlo, los datos sabrán pintar y no se
    // podrán probar solos.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consumo guardado')),
    );
  }

  Future<void> _recargarHistorial() async {
    setState(() => _cargando = true);

    final List<Map<String, Object>> filas;
    if (_usarNube) {
      // MEZCLA 3 (continúa) — Leer de la "nube" y traducir JSON a mano.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      filas = _servidor
          .where((j) => j['laboratorio'] == _laboratorio)
          .map(
            (j) => <String, Object>{
              'laboratorio': j['laboratorio']! as String,
              'litros': (j['litros']! as num).toDouble(),
              'fecha': DateTime.parse(j['fecha']! as String),
            },
          )
          .toList();
    } else {
      filas = _memoria.where((c) => c['laboratorio'] == _laboratorio).toList();
    }

    if (!mounted) return;
    setState(() {
      _historial = filas;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _historial.fold<double>(
      0,
      (suma, c) => suma + (c['litros']! as double),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('EcoTrack — Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _laboratorio,
              decoration: const InputDecoration(labelText: 'Laboratorio'),
              items: [
                for (final lab in _laboratorios)
                  DropdownMenuItem(value: lab, child: Text(lab)),
              ],
              onChanged: (lab) => _cambiarLaboratorio(lab!),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('campoLitros'),
              controller: _litros,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Litros',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _cargando ? null : _guardar,
              icon: _cargando
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
            const Divider(height: 32),
            Text(
              'Historial de $_laboratorio · ${total.toStringAsFixed(1)} L',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Expanded(
              child: _historial.isEmpty
                  ? const Center(child: Text('Sin consumos todavía'))
                  : ListView(
                      children: [
                        for (final c in _historial.reversed)
                          ListTile(
                            leading: const Icon(Icons.water_drop),
                            title: Text('${c['litros']} L'),
                            subtitle: Text(
                              '${(c['fecha']! as DateTime).hour}:'
                              '${(c['fecha']! as DateTime).minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
