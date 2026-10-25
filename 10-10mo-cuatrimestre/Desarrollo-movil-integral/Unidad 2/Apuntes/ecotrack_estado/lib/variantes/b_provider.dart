// ALTERNATIVA B1 — provider.
//
// Cableado: ChangeNotifierProvider pone el MISMO ConsumosViewModel en el
// árbol. Cualquier pantalla lo pide con context.watch / context.read,
// sin recibirlo por constructor.
// Lo que no cambia: ConsumosViewModel y ConsumoRepository.

import 'package:ecotrack_estado/datos/consumo_repository.dart';
import 'package:ecotrack_estado/presentacion/consumos_view_model.dart';
import 'package:ecotrack_estado/presentacion/vistas.dart';
import 'package:flutter/material.dart';

// Importación de dependencia de gestión de estados - provider
import 'package:provider/provider.dart';

class AppProvider extends StatelessWidget{

  const AppProvider({super.key, required this.repositorio});

  final ConsumoRepository repositorio;

  @override
  Widget build(BuildContext context){
    return ChangeNotifierProvider(
        // Crea el viewModel una sola vez - provider lo libera por si solo (no hay dispose)
        create: (_) => ConsumosViewModel(repositorio),
        child: MaterialApp(
          theme: ThemeData(colorSchemeSeed: Colors.purple),
          home: const DosPantallas(
              titulo: 'B. Provider',
              registro: RegistroProvider(),
              historial: HistorialProvider(),
          ),
        ),

    );
  }
}


class RegistroProvider extends StatelessWidget {
  const RegistroProvider({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConsumosViewModel>();

    return FormularioRegistro(
      alGuardar: vm.guardar,
      error: vm.error,
      guardando: vm.guardando,
    );
  }
}

class HistorialProvider extends StatelessWidget {

  const HistorialProvider({super.key});

  @override
  Widget build(BuildContext context){
    final consumos = context.watch<ConsumosViewModel>().consumos;

    return ListaHistorial(consumos: consumos);
  }
}