// Etapa 3 — único dueño del estado compartido. Avisa, no dibuja.

import 'package:flutter/foundation.dart';

import '../datos/consumo_repository.dart';
import '../dominio/consumo.dart';
import '../dominio/meta.dart';

class ConsumosViewModel extends ChangeNotifier {
  // Recibe el contrato: no sabe si los datos vienen de memoria o de la nube.
  ConsumosViewModel(this._repositorio);

  final ConsumoRepository _repositorio;

  // Estado compartido.
  List<Consumo> consumos = const [];
  String? error;
  bool guardando = false;
  double meta = metaInicial;

  // Estado derivado: se calcula cada vez, nunca se guarda.
  double get total => consumos.fold(0.0, (suma, c) => suma + c.litros);
  double get avance => avanceDeMeta(total: total, meta: meta);
  bool get metaSuperada => total > meta;

  // Lee la fuente de verdad y avisa.
  Future<void> cargar() async {
    consumos = await _repositorio.todos();
    notifyListeners();
  }

  // Regresa true si se guardó.
  Future<bool> guardar(String laboratorio, String litrosTexto) async {
    // 1. Convierte el texto: acepta espacios y coma decimal.
    final litros = double.tryParse(litrosTexto.trim().replaceAll(',', '.'));

    // 2. La regla la decide el dominio; si falla, no se toca el repositorio.
    final mensaje = validarLitros(litros);
    if (mensaje != null) {
      error = mensaje;
      notifyListeners();
      return false;
    }

    // 3. Marca que está guardando y limpia el error.
    guardando = true;
    error = null;
    notifyListeners();

    // 4. Guarda y vuelve a leer la lista completa del repositorio.
    await _repositorio.guardar(
      Consumo(laboratorio: laboratorio, litros: litros!),
    );
    consumos = await _repositorio.todos();

    // 5. Termina y avisa.
    guardando = false;
    notifyListeners();
    return true;
  }

  // El mínimo lo decide ajustarMeta, no el ViewModel.
  void subirMeta() {
    meta = ajustarMeta(meta, pasoMeta);
    notifyListeners();
  }

  void bajarMeta() {
    meta = ajustarMeta(meta, -pasoMeta);
    notifyListeners();
  }
}
