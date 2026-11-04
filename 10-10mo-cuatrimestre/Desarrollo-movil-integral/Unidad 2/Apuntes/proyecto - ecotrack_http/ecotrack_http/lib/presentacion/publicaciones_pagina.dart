import 'package:flutter/material.dart';

import 'publicaciones_view_model.dart';
import 'tarjeta_publicacion.dart';

class PublicacionesPagina extends StatelessWidget {
  const PublicacionesPagina({
    super.key,
    required this.vm,
    this.acciones = const [],
  });

  final PublicacionesViewModel vm;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EcoTrack · HTTP'), actions: acciones),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  key: const Key('cargar'),
                  onPressed: vm.cargando ? null : vm.cargar,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Cargar publicaciones'),
                ),
                const SizedBox(height: 16),
                Expanded(child: _contenido(vm.estado)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _contenido(EstadoPublicaciones estado) {
    return switch (estado) {
      Inicial() => const Center(
        child: Text('Pulsa el botón para consultar el servicio.'),
      ),
      Cargando() => const Center(child: CircularProgressIndicator()),
      Vacio() => const Center(child: Text('No hay publicaciones.')),
      ConError(:final mensaje) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: vm.cargar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      ConDatos(:final publicaciones) => ListView.separated(
        itemCount: publicaciones.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) =>
            TarjetaPublicacion(publicacion: publicaciones[i]),
      ),
    };
  }
}
