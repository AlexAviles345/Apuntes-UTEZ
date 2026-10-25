import 'package:dpendencies/dominio/consumo.dart';


abstract class ConsumoRepository {

  Future<void> guardar(Consumo consumo);
  Future<List<Consumo>> todos();

}

class MemoriaConsumoRepository implements ConsumoRepository {
  final List<Consumo> _consumos = [];

  @override
  Future<void> guardar(Consumo consumo) async => _consumos.add(consumo);

  @override
  Future<List<Consumo>> todos() async => List.unmodifiable(_consumos);
}

