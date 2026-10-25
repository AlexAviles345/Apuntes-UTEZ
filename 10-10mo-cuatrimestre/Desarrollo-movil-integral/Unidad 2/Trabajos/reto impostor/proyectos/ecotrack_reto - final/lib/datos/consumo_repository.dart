import '../dominio/consumo.dart';

/// Contrato común: sus consumidores no eligen entre memoria y nube.
abstract class ConsumoRepository {
  Future<void> guardar(Consumo consumo);

  Future<List<Consumo>> listarPorLaboratorio(String laboratorio);
}
