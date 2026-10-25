import 'package:flutter/material.dart';

import 'datos/consumo_repository.dart';
import 'datos/memoria_consumo_repository.dart';
import 'datos/consumo_service.dart';
import 'datos/nube_consumo_repository.dart';
import 'presentacion/registro_page.dart';
import 'presentacion/registro_view_model.dart';

const bool usarNube = false;

/// Único punto que elige y construye la implementación de almacenamiento.
void main() {
  final ConsumoRepository repositorio = usarNube
      ? NubeConsumoRepository(ConsumoService())
      : MemoriaConsumoRepository();

  runApp(EcoTrackApp(repositorio: repositorio));
}

class EcoTrackApp extends StatelessWidget {
  final ConsumoRepository repositorio;

  const EcoTrackApp({super.key, required this.repositorio});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTrack',
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: RegistroPage(viewModel: RegistroViewModel(repositorio)),
    );
  }
}
