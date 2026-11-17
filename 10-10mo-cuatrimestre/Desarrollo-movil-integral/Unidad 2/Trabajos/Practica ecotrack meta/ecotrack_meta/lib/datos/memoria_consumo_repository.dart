// Etapa 2 — implementación en memoria del contrato.

import '../dominio/consumo.dart';
import 'consumo_repository.dart';

class MemoriaConsumoRepository implements ConsumoRepository {
  // Fuente de verdad: solo este repositorio la modifica.
  final List<Consumo> _consumos = [];

  // async aunque responda al instante: una fuente real (red, disco) tardaría.
  @override
  Future<void> guardar(Consumo consumo) async {
    _consumos.add(consumo);
  }

  // Copia no modificable: nadie de fuera puede alterar la lista interna.
  @override
  Future<List<Consumo>> todos() async => List.unmodifiable(_consumos);
}
