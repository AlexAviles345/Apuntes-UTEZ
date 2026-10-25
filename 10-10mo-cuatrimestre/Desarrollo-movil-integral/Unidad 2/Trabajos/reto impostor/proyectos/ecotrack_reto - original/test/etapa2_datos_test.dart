// ETAPA 2 — DATOS
// Pasa cuando existen el contrato, la implementación en memoria,
// el servicio que finge la API y la implementación "nube".
//
//   flutter test test/etapa2_datos_test.dart -r expanded
//
// NO EDITAR: el docente vuelve a correr una copia limpia de este archivo.

import 'package:ecotrack_reto/datos/consumo_repository.dart';
import 'package:ecotrack_reto/datos/consumo_service.dart';
import 'package:ecotrack_reto/datos/memoria_consumo_repository.dart';
import 'package:ecotrack_reto/datos/nube_consumo_repository.dart';
import 'package:ecotrack_reto/dominio/consumo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoy = DateTime(2026, 9, 4, 10, 30);

  final quimica = Consumo(laboratorio: 'Lab Química', litros: 12.5, fecha: hoy);
  final redes = Consumo(laboratorio: 'Lab Redes', litros: 3, fecha: hoy);

  group('MemoriaConsumoRepository', () {
    test('cumple el contrato ConsumoRepository', () {
      expect(MemoriaConsumoRepository(), isA<ConsumoRepository>());
    });

    test('guarda y lista solo los consumos de ese laboratorio', () async {
      final repo = MemoriaConsumoRepository();

      await repo.guardar(quimica);
      await repo.guardar(redes);

      final lista = await repo.listarPorLaboratorio('Lab Química');
      expect(lista, hasLength(1));
      expect(lista.single.litros, 12.5);
    });
  });

  group('ConsumoService', () {
    test('habla JSON: recibe y devuelve mapas', () async {
      final service = ConsumoService();

      await service.post({
        'laboratorio': 'Lab Física',
        'litros': 7.0,
        'fecha': hoy.toIso8601String(),
      });

      final filas = await service.get('Lab Física');
      expect(filas.single['litros'], 7.0);
    });
  });

  group('NubeConsumoRepository', () {
    test('cumple el MISMO contrato ConsumoRepository', () {
      expect(NubeConsumoRepository(ConsumoService()), isA<ConsumoRepository>());
    });

    test('traduce Consumo a JSON y de regreso sin perder datos', () async {
      final repo = NubeConsumoRepository(ConsumoService());

      await repo.guardar(quimica);
      await repo.guardar(redes);

      final lista = await repo.listarPorLaboratorio('Lab Química');
      expect(lista, hasLength(1));
      expect(lista.single.laboratorio, 'Lab Química');
      expect(lista.single.litros, 12.5);
      expect(lista.single.fecha, hoy);
    });
  });
}
