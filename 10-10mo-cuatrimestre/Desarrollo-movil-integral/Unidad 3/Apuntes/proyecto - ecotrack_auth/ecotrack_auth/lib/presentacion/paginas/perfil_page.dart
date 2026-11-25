// Pantalla PROTEGIDA anidada (/inicio/perfil).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../sesion_view_model.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SesionViewModel>().usuario;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Correo'),
            subtitle: Text(usuario?.correo ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Identificador (uid)'),
            subtitle: Text(usuario?.uid ?? ''),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            key: const Key('salirPerfil'),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            onPressed: () => context.read<SesionViewModel>().cerrarSesion(),
          ),
        ],
      ),
    );
  }
}