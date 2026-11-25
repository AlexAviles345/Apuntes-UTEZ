// Pantalla pública: inicio de sesión.
// No navega al terminar: si el inicio fue exitoso, el router ve ConSesion y
// redirige solo. La pantalla solo pide, muestra "procesando" y el error.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../rutas.dart';
import '../sesion_view_model.dart';

class EntrarPage extends StatefulWidget {
  const EntrarPage({super.key});

  @override
  State<EntrarPage> createState() => _EntrarPageState();
}

class _EntrarPageState extends State<EntrarPage> {
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _ocultar = true;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  void _entrar() {
    context.read<SesionViewModel>().iniciarSesion(
      _correo.text,
      _contrasena.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('EcoTrack · Entrar')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            key: const Key('correo'),
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Correo'),
          ),
          TextField(
            key: const Key('contrasena'),
            controller: _contrasena,
            obscureText: _ocultar,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Contraseña',
              suffixIcon: IconButton(
                tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _ocultar = !_ocultar),
              ),
            ),
            onSubmitted: (_) => _entrar(),
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
            onPressed: sesion.procesando ? null : _entrar,
            child: Text(sesion.procesando ? 'Entrando…' : 'Entrar'),
          ),
          TextButton(
            onPressed: () {
              context.read<SesionViewModel>().limpiarError();
              context.go(Rutas.registro);
            },
            child: const Text('Crear cuenta'),
          ),
        ],
      ),
    );
  }
}