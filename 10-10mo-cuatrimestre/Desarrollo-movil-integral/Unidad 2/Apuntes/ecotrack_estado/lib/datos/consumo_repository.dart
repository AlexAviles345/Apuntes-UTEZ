// DATOS — igual en las tres variantes.
// Criterio "Sustitución": ninguna variante importa MemoriaConsumoRepository
// fuera de su main. Cambiar la fuente no toca pantallas.

// Importa la entidad Consumo del dominio.
import '../dominio/consumo.dart';

// Contrato (interfaz) del repositorio: qué se puede hacer, no cómo.
abstract class ConsumoRepository {
  // Guarda un consumo; es asíncrono porque una fuente real tardaría (red, disco).
  Future<void> guardar(Consumo consumo);

  // Devuelve todos los consumos guardados.
  Future<List<Consumo>> todos();
}

// Implementación concreta que guarda los consumos en memoria (se pierden al cerrar).
class MemoriaConsumoRepository implements ConsumoRepository {
  // Lista privada donde realmente viven los datos: es la fuente de verdad.
  final List<Consumo> _consumos = [];

  // Indica que este método cumple el contrato de ConsumoRepository.
  @override
  // Agrega el consumo a la lista interna.
  Future<void> guardar(Consumo consumo) async => _consumos.add(consumo);

  // Indica que este método cumple el contrato de ConsumoRepository.
  @override
  // Devuelve una copia que no se puede modificar, para que nadie altere la lista por fuera.
  Future<List<Consumo>> todos() async => List.unmodifiable(_consumos);
}
