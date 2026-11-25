// Pantalla pública: registro de una cuenta nueva.
// En Firebase, registrarse también inicia sesión: el router redirige solo.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../rutas.dart';
import '../sesion_view_model.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  void _registrar() {
    context.read<SesionViewModel>().registrar(
      _correo.text,
      _contrasena.text,
      _confirmacion.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('EcoTrack · Crear cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            key: const Key('correo'),
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo'),
          ),
          TextField(
            key: const Key('contrasena'),
            controller: _contrasena,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(labelText: 'Contraseña'),
          ),
          TextField(
            key: const Key('confirmacion'),
            controller: _confirmacion,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Repite la contraseña',
            ),
          ),
          const SizedBox(height: 16),
          if (sesion.error != null)
            Text(
              sesion.error!,
              key: const Key('error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: sesion.procesando ? null : _registrar,
            child: Text(sesion.procesando ? 'Creando…' : 'Crear cuenta'),
          ),
          TextButton(
            onPressed: () {
              context.read<SesionViewModel>().limpiarError();
              context.go(Rutas.entrar);
            },
            child: const Text('Ya tengo cuenta'),
          ),
        ],
      ),
    );
  }
}