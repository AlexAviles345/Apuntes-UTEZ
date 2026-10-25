import '../dominio/consumo.dart';
import 'consumo_repository.dart';

/// Conserva los consumos durante la vida de esta instancia, sin persistencia.
class MemoriaConsumoRepository implements ConsumoRepository {
  final List<Consumo> _memoria = [];

  @override
  Future<void> guardar(Consumo consumo) async {
    _memoria.add(consumo);
  }

  @override
  Future<List<Consumo>> listarPorLaboratorio(String laboratorio) async {
    return _memoria.where((c) => c.laboratorio == laboratorio).toList();
  }
}
