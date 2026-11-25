// Pantalla PROTEGIDA. Solo se llega aquí con sesión: lo garantiza el router.
// En S07 aquí se listan los consumos de la persona, leídos de Firestore.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../rutas.dart';
import '../sesion_view_model.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionViewModel>().usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoTrack · Inicio'),
        actions: [
          IconButton(
            key: const Key('irPerfil'),
            tooltip: 'Perfil',
            icon: const Icon(Icons.person),
            // push apila Perfil encima de Inicio: sirve para demostrar que,
            // al cerrar sesión desde Perfil, la pila completa desaparece.
            onPressed: () => context.push(Rutas.perfil),
          ),
          IconButton(
            key: const Key('salir'),
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<SesionViewModel>().cerrarSesion(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.water_drop, size: 48),
              const SizedBox(height: 16),
              Text(
                'Hola, ${usuario?.correo ?? ''}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Tus consumos aparecerán aquí.'),
            ],
          ),
        ),
      ),
    );
  }
}