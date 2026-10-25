import 'package:flutter/foundation.dart';

import '../datos/consumo_repository.dart';
import '../dominio/consumo.dart';
import '../dominio/regla_consumo.dart';

/// Estado y orquestación de registro; recibe el contrato y un reloj sustituible.
class RegistroViewModel extends ChangeNotifier {
  final ConsumoRepository _repositorio;
  final DateTime Function() _reloj;

  RegistroViewModel(this._repositorio, {DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now;

  String laboratorio = laboratoriosUtez.first;
  bool cargando = false;
  String? error;
  List<Consumo> historial = [];

  double get totalLitros {
    return historial.fold<double>(0, (suma, consumo) => suma + consumo.litros);
  }

  /// Cambia el filtro y vuelve a consultar el historial mediante el contrato.
  Future<void> cambiarLaboratorio(String nuevo) async {
    laboratorio = nuevo;
    error = null;
    await _recargarHistorial();
  }

  Future<void> _recargarHistorial() async {
    cargando = true;
    notifyListeners();

    historial = await _repositorio.listarPorLaboratorio(laboratorio);
    cargando = false;
    notifyListeners();
  }

  /// Convierte la entrada, delega las reglas al dominio y coordina el guardado.
  Future<bool> guardar(String litrosTexto) async {
    final litros = double.tryParse(litrosTexto.trim().replaceAll(',', '.'));

    if (litros == null) {
      error = 'Escribe los litros con número';
      notifyListeners();
      return false;
    }

    final fecha = _reloj();

    final consumo = Consumo(
      laboratorio: laboratorio,
      litros: litros,
      fecha: fecha,
    );

    error = ReglaConsumo.validar(consumo, hoy: _reloj());

    if (error != null) {
      notifyListeners();
      return false;
    }

    cargando = true;
    error = null;
    notifyListeners();

    await _repositorio.guardar(consumo);
    await _recargarHistorial();
    return true;
  }
}
