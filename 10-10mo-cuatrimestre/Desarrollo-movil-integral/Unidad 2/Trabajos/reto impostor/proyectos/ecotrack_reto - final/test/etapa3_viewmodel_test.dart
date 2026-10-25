// ETAPA 3 — VIEWMODEL
// Pasa cuando RegistroViewModel orquesta la regla y el repositorio.
// Se prueba con un repositorio espía: sin pantalla y sin red.
//
//   flutter test test/etapa3_viewmodel_test.dart -r expanded
//
// NO EDITAR: el docente vuelve a correr una copia limpia de este archivo.

import 'package:ecotrack_reto/datos/consumo_repository.dart';
import 'package:ecotrack_reto/dominio/consumo.dart';
import 'package:ecotrack_reto/presentacion/registro_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class RepositorioEspia implements ConsumoRepository {
  final List<Consumo> guardados = [];

  @override
  Future<void> guardar(Consumo consumo) async => guardados.add(consumo);

  @override
  Future<List<Consumo>> listarPorLaboratorio(String laboratorio) async =>
      guardados.where((c) => c.laboratorio == laboratorio).toList();
}

void main() {
  final hoy = DateTime(2026, 9, 4, 10);

  late RepositorioEspia repo;
  late RegistroViewModel vm;

  setUp(() {
    repo = RepositorioEspia();
    vm = RegistroViewModel(repo, reloj: () => hoy);
  });

  test('empieza en el primer laboratorio, sin error y sin historial', () {
    expect(vm.laboratorio, laboratoriosUtez.first);
    expect(vm.error, isNull);
    expect(vm.cargando, isFalse);
    expect(vm.historial, isEmpty);
  });

  test('con litros válidos guarda en el repositorio y actualiza historial',
      () async {
    final ok = await vm.guardar('12.5');

    expect(ok, isTrue);
    expect(repo.guardados, hasLength(1));
    expect(repo.guardados.single.fecha, hoy);
    expect(vm.historial.single.litros, 12.5);
    expect(vm.error, isNull);
    expect(vm.cargando, isFalse);
  });

  test('acepta coma decimal: "12,5" son 12.5 litros', () async {
    await vm.guardar('12,5');

    expect(repo.guardados.single.litros, 12.5);
  });

  test('con litros inválidos muestra error y no llama al repositorio',
      () async {
    final ok = await vm.guardar('0');

    expect(ok, isFalse);
    expect(repo.guardados, isEmpty);
    expect(vm.error, 'Los litros deben ser mayores que cero');
  });

  test('con texto que no es número muestra error y no guarda', () async {
    final ok = await vm.guardar('abc');

    expect(ok, isFalse);
    expect(repo.guardados, isEmpty);
    expect(vm.error, isNotNull);
  });

  test('avisa a la vista (notifyListeners) cuando cambia', () async {
    var avisos = 0;
    vm.addListener(() => avisos++);

    await vm.guardar('5');

    expect(avisos, greaterThan(0));
  });

  test('cambiarLaboratorio filtra el historial y limpia el error', () async {
    await vm.guardar('12.5');
    await vm.guardar('0');
    expect(vm.error, isNotNull);

    await vm.cambiarLaboratorio('Lab Redes');

    expect(vm.laboratorio, 'Lab Redes');
    expect(vm.error, isNull);
    expect(vm.historial, isEmpty);
  });

  test('totalLitros suma el historial del laboratorio actual', () async {
    await vm.guardar('10');
    await vm.guardar('2.5');

    expect(vm.totalLitros, 12.5);
  });
}
