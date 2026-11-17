// Etapa 2 — contrato de la fuente de datos. Habla como el dominio.

import '../dominio/consumo.dart';

abstract class ConsumoRepository {
  Future<void> guardar(Consumo consumo);
  Future<List<Consumo>> todos();
}
