import 'package:dpendencies/datos/consumo_repositorio.dart';
import 'package:dpendencies/presentacion/registro_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(EcoTrackApp(repsitorio: MemoriaConsumoRepository()));
}


class EcoTrackApp extends StatelessWidget{
  const EcoTrackApp({super.key, required this.repsitorio});

  final ConsumoRepository repsitorio;

  @override
  Widget build(
      BuildContext context
      ){
    return MaterialApp(
      title: 'EcoTrackApp',
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: RegistroPage(repositorio: repsitorio ),
    );
  }


}
