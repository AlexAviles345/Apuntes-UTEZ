// ALTERNATIVA A — ChangeNotifier (viene con Flutter).
//
// Cableado: el ViewModel se crea una vez y se pasa por constructor a cada
// pantalla. Cada pantalla lo escucha con ListenableBuilder.
// Costo: si hay muchas pantallas anidadas, hay que pasarlo de mano en mano.

import 'package:flutter/material.dart';

import '../datos/consumo_repository.dart';
import '../presentacion/consumos_view_model.dart';
import '../presentacion/vistas.dart';

class AppChangeNotifier extends StatefulWidget{
  const AppChangeNotifier({super.key, required this.repositorio});

  final ConsumoRepository repositorio;

  @override
  State<AppChangeNotifier> createState() => _AppChangeNotifierState();
}

class _AppChangeNotifierState extends State<AppChangeNotifier>{
  late final _vm = ConsumosViewModel(widget.repositorio);

  @override
  // Este metodo se llama cuando la app ssale del arbol
  void dispose(){
    // Libera el viewmodel y sus listeners: quien lo creo lo destruye
    _vm.dispose();
    // Completa la limpieza de la clase padre
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: DosPantallas(
          titulo: 'A. ChangeNotifier',
          registro: RegistroCN(vm: _vm),
          historial: HistorialCN(vm: _vm),
      ),
    );

  }
}

// Adaptador de registro para la variante changeNotifier
class RegistroCN extends StatelessWidget {
  const RegistroCN({super.key, required this.vm});

  final ConsumosViewModel vm;

  @override
  Widget build(BuildContext context){
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => FormularioRegistro(
        alGuardar: vm.guardar,
        error: vm.error,
        guardando: vm.guardando
      ),
    );
  }
}

/*
// Adaptador de Historial para la variante A.
class HistorialCN extends StatelessWidget {
  // Constructor: recibe el ViewModel.
  const HistorialCN();
}
*/
class HistorialCN extends StatelessWidget {
  const HistorialCN({super.key, required this.vm});
  final ConsumosViewModel vm;

  @override
  Widget build(BuildContext context) {

//que va a pasar con lo que esta escuchando
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => ListaHistorial(
        consumos: vm.consumos,
      ),
    );
  }
}