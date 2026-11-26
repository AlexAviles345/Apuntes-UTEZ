import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ambiente.dart';
import 'diagnostico.dart';
import 'logger_seguro.dart';

void main() {
  LoggerSeguro.info('Arranque', 'EcoTrack modos · ambiente=${Ambiente.actual.nombre}');
  if (kDebugMode) {
    LoggerSeguro.debug('SecretoDemo', 'token=demo-solo-debug-nunca-en-release');
  }
  runApp(const EcoTrackModosApp());
}

class EcoTrackModosApp extends StatelessWidget {
  const EcoTrackModosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTrack · Modos',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Ambiente.actual.color,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const PanelModosPage(),
    );
  }
}

class PanelModosPage extends StatefulWidget {
  const PanelModosPage({super.key});

  @override
  State<PanelModosPage> createState() => _PanelModosPageState();
}

class _PanelModosPageState extends State<PanelModosPage> {
  String _ultimaAccion = 'Sin acciones aún';
  final List<String> _bitacora = [];

  void _registrar(String mensaje) {
    setState(() {
      _ultimaAccion = mensaje;
      _bitacora.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)} · $mensaje');
      if (_bitacora.length > 8) _bitacora.removeLast();
    });
  }

  void _simularConsumo() {
    // En debug/profile queda rastro útil; en release el logger silencia lo sensible.
    LoggerSeguro.debug('Consumo', 'usuario=alumno@utez.edu.mx litros=12.5');
    LoggerSeguro.info('Consumo', 'Registro guardado localmente');
    _registrar('Consumo simulado (revisa la consola según el modo)');
  }

  void _provocarFalloControlado() {
    try {
      Diagnostico.dividirLitros(total: 10, personas: 0);
      _registrar('No debió llegar aquí');
    } catch (e, st) {
      LoggerSeguro.error('FalloControlado', e, st);
      _registrar('Fallo capturado: $e');
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Análisis del fallo'),
          content: Text(Diagnostico.explicarFallo(e)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modo = modoActual();
    final ambiente = Ambiente.actual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoTrack · Modos de compilación'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tarjeta(
            titulo: 'Modo de ejecución',
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(modo.etiqueta, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(modo.descripcion),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('kDebugMode=$kDebugMode')),
                    Chip(label: Text('kProfileMode=$kProfileMode')),
                    Chip(label: Text('kReleaseMode=$kReleaseMode')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _tarjeta(
            titulo: 'Ambiente (--dart-define=AMBIENTE=…)',
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ambiente.nombre.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: ambiente.color,
                        )),
                const SizedBox(height: 8),
                Text('API base: ${ambiente.apiBase}'),
                Text('Logs verbosos: ${ambiente.logsVerbosos ? "sí" : "no"}'),
                Text('Banner de depuración: ${ambiente.mostrarBanner ? "sí" : "no"}'),
                const SizedBox(height: 8),
                const Text(
                  'Prueba: flutter run --dart-define=AMBIENTE=qa  |  AMBIENTE=prod',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _tarjeta(
            titulo: 'Experimentos de clase',
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _simularConsumo,
                  child: const Text('1 · Simular registro + logs'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _provocarFalloControlado,
                  child: const Text('2 · Provocar fallo controlado'),
                ),
                const SizedBox(height: 8),
                Text(_ultimaAccion, style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _tarjeta(
            titulo: 'Bitácora en pantalla',
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _bitacora.isEmpty
                  ? [const Text('Vacía')]
                  : _bitacora.map((l) => Text('• $l')).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _tarjeta(
            titulo: 'Qué debe notar el grupo',
            hijo: const Text(
              '• En debug: asserts activos, hot reload, banner "DEBUG", logs detallados.\n'
              '• En profile: rendimiento realista, sin asserts costosos; útil con DevTools.\n'
              '• En release: sin banner, sin logs sensibles, tree-shaking, optimizado.\n'
              '• Un token o correo en print() visible en release = fuga (A04 lo comprobará).',
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta({required String titulo, required Widget hijo}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            hijo,
          ],
        ),
      ),
    );
  }
}

class ModoInfo {
  const ModoInfo(this.etiqueta, this.descripcion);
  final String etiqueta;
  final String descripcion;
}

ModoInfo modoActual() {
  if (kReleaseMode) {
    return const ModoInfo(
      'RELEASE',
      'Listo para distribución. Optimizado, sin asserts de depuración y sin información sensible en consola.',
    );
  }
  if (kProfileMode) {
    return const ModoInfo(
      'PROFILE',
      'Para medir rendimiento con DevTools. Casi como release, pero con sondas de profiling.',
    );
  }
  return const ModoInfo(
    'DEBUG',
    'Desarrollo diario: hot reload, asserts, banner DEBUG y logs verbosos permitidos.',
  );
}
