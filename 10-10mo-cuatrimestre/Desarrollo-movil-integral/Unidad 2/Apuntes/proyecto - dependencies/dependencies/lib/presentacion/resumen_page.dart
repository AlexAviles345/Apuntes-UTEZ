// "Pantalla de resumen": solo aparece si el formulario fue válido.
// Confirmar = guardar en el repositorio y abrir el historial.

import 'package:flutter/material.dart';

import '../datos/consumo_repositorio.dart';
import '../dominio/consumo.dart';
import 'historial_page.dart';

class ResumenPage extends StatelessWidget {
  const ResumenPage({
    super.key,
    required this.repositorio,
    required this.consumo,
  });

  final ConsumoRepository repositorio;
  final Consumo consumo;

  Future<void> _confirmar(BuildContext context) async {
    await repositorio.guardar(consumo);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HistorialPage(repositorio: repositorio),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: const Text('Laboratorio'),
              trailing: Text(consumo.laboratorio),
            ),
            ListTile(
              title: const Text('Litros'),
              trailing: Text('${consumo.litros}'),
            ),
            ListTile(
              title: const Text('kWh'),
              trailing: Text('${consumo.kwh}'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _confirmar(context),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}