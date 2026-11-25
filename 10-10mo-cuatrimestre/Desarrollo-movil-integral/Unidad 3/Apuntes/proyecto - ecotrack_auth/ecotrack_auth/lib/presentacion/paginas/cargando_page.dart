// Se ve solo mientras el proveedor responde si hay una sesión guardada.
// Sin esta pantalla, la app mostraría "Entrar" medio segundo y luego saltaría
// a Inicio: un parpadeo que confunde y que deja ver una pantalla equivocada.

import 'package:flutter/material.dart';

class CargandoPage extends StatelessWidget {
  const CargandoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verificando tu sesión…'),
          ],
        ),
      ),
    );
  }
}