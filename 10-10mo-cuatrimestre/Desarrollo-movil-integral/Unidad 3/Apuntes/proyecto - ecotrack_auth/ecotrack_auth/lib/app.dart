// Composición: crea el ViewModel de sesión y el router UNA sola vez,
// y los entrega a toda la app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'datos/auth_repository.dart';
import 'datos/memoria_auth_repository.dart';
import 'presentacion/rutas.dart';
import 'presentacion/sesion_view_model.dart';

class EcoTrackAuthApp extends StatefulWidget {
  const EcoTrackAuthApp({super.key, required this.repositorio});

  final AuthRepository repositorio;

  @override
  State<EcoTrackAuthApp> createState() => _EcoTrackAuthAppState();
}

class _EcoTrackAuthAppState extends State<EcoTrackAuthApp> {
  late final _sesion = SesionViewModel(widget.repositorio);
  // El router escucha a _sesion; si se creara en build, se perdería la pila
  // de navegación en cada redibujo.
  late final _router = crearRouter(_sesion);

  @override
  void dispose() {
    _router.dispose();
    _sesion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repositorio = widget.repositorio;
    return ChangeNotifierProvider.value(
      value: _sesion,
      child: MaterialApp.router(
        title: 'EcoTrack',
        theme: ThemeData(colorSchemeSeed: Colors.teal),
        routerConfig: _router,
        // Solo en modo simulado: un interruptor para provocar "sin red" en vivo.
        builder: (context, child) => repositorio is MemoriaAuthRepository
            ? _InterruptorRed(repositorio: repositorio, child: child!)
            : child!,
      ),
    );
  }
}

class _InterruptorRed extends StatefulWidget {
  const _InterruptorRed({required this.repositorio, required this.child});

  final MemoriaAuthRepository repositorio;
  final Widget child;

  @override
  State<_InterruptorRed> createState() => _InterruptorRedState();
}

class _InterruptorRedState extends State<_InterruptorRed> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 12,
          bottom: 12,
          child: SafeArea(
            child: Material(
              type: MaterialType.transparency,
              child: FilterChip(
                key: const Key('simularSinRed'),
                avatar: const Icon(Icons.wifi_off, size: 18),
                label: const Text('Simular sin red'),
                selected: widget.repositorio.sinRed,
                onSelected: (v) =>
                    setState(() => widget.repositorio.sinRed = v),
              ),
            ),
          ),
        ),
      ],
    );
  }
}