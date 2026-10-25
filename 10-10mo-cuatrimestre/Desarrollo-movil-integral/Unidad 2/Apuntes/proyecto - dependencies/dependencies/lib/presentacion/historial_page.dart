import 'package:flutter/material.dart';

import '../datos/consumo_repositorio.dart';
import '../dominio/consumo.dart';

class HistorialPage extends StatelessWidget {
  const HistorialPage({super.key, required this.repositorio});

  final ConsumoRepository repositorio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: FutureBuilder<List<Consumo>>(
        future: repositorio.todos(),
        builder: (context, snapshot) {
          final consumos = snapshot.data ?? const [];
          if (consumos.isEmpty) {
            return const Center(child: Text('Sin registros'));
          }
          return ListView(
            children: [
              for (final c in consumos)
                ListTile(
                  leading: const Icon(Icons.eco),
                  title: Text(c.laboratorio),
                  subtitle: Text('${c.litros} L · ${c.kwh} kWh'),
                ),
            ],
          );
        },
      ),
    );
  }
}