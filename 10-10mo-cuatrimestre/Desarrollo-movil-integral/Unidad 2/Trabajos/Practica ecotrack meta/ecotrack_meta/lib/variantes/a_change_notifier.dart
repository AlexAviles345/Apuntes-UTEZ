// Etapa 4 — variante A: ChangeNotifier puro, el ViewModel viaja por constructor.

import 'package:flutter/material.dart';

import '../datos/consumo_repository.dart';
import '../presentacion/consumos_view_model.dart';
import '../presentacion/vistas.dart';

class AppChangeNotifier extends StatefulWidget {
  const AppChangeNotifier({super.key, required this.repositorio});

  final ConsumoRepository repositorio;

  @override
  State<AppChangeNotifier> createState() => _AppChangeNotifierState();
}

class _AppChangeNotifierState extends State<AppChangeNotifier> {
  // Se crea una sola vez: si viviera en build, se perderían los datos.
  late final ConsumosViewModel _vm = ConsumosViewModel(widget.repositorio);

  @override
  void initState() {
    super.initState();
    _vm.cargar();
  }

  // Quien crea el ViewModel es quien lo libera.
  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTrack Meta',
      home: PantallasEcoTrack(
        titulo: 'A · ChangeNotifier',
        registro: RegistroCN(vm: _vm),
        historial: HistorialCN(vm: _vm),
        meta: MetaCN(vm: _vm),
      ),
    );
  }
}

class RegistroCN extends StatelessWidget {
  const RegistroCN({super.key, required this.vm});

  final ConsumosViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => FormularioRegistro(
        alGuardar: vm.guardar,
        error: vm.error,
        guardando: vm.guardando,
      ),
    );
  }
}

class HistorialCN extends StatelessWidget {
  const HistorialCN({super.key, required this.vm});

  final ConsumosViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) =>
          ListaHistorial(consumos: vm.consumos, total: vm.total),
    );
  }
}

class MetaCN extends StatelessWidget {
  const MetaCN({super.key, required this.vm});

  final ConsumosViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => PanelMeta(
        usado: vm.total,
        meta: vm.meta,
        avance: vm.avance,
        superada: vm.metaSuperada,
        alSubir: vm.subirMeta,
        alBajar: vm.bajarMeta,
      ),
    );
  }
}
