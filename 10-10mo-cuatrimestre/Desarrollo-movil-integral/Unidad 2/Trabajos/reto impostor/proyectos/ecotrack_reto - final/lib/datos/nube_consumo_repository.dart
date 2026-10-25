import '../dominio/consumo.dart';
import 'consumo_repository.dart';
import 'consumo_service.dart';

/// Traduce entre el dominio y los mapas del servicio; el modelo no conoce JSON.
class NubeConsumoRepository implements ConsumoRepository {
  NubeConsumoRepository(this._service);

  final ConsumoService _service;

  @override
  Future<void> guardar(Consumo consumo) async {
    await _service.post({
      'laboratorio': consumo.laboratorio,
      'litros': consumo.litros,
      'fecha': consumo.fecha.toIso8601String(),
    });
  }

  @override
  Future<List<Consumo>> listarPorLaboratorio(String laboratorio) async {
    final filas = await _service.get(laboratorio);
    return filas
        .map(
          (json) => Consumo(
            laboratorio: json['laboratorio']! as String,
            litros: (json['litros']! as num).toDouble(),
            fecha: DateTime.parse(json['fecha']! as String),
          ),
        )
        .toList();
  }
}
