// ALTERNATIVA B2 — riverpod.
//
// Cableado: los providers son globales y se leen con ref.watch / ref.read.
// El Notifier ocupa el lugar del ViewModel; el estado es un valor inmutable
// (EstadoConsumos) que se reemplaza completo en cada cambio.
// Lo que no cambia: ConsumoRepository. Se entrega con repositorioProvider
// y en los tests se sustituye con overrides, sin tocar pantallas.

// Importa los widgets de Material Design.
import 'package:flutter/material.dart';
// Importa riverpod para Flutter (Provider, Notifier, ConsumerWidget, ref...).
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importa el contrato y la implementación en memoria del repositorio.
import '../datos/consumo_repository.dart';
// Importa Consumo y la regla validarLitros.
import '../dominio/consumo.dart';
// Importa los widgets compartidos.
import '../presentacion/vistas.dart';

// Provider global que entrega el repositorio; en los tests se reemplaza con un override.
final repositorioProvider = Provider<ConsumoRepository>(
// Función que crea el valor: por defecto, el repositorio en memoria.
      (ref) => MemoriaConsumoRepository(),
);

// Estado inmutable de la pantalla: no se modifica, se reemplaza completo.
class EstadoConsumos {
// Constructor const con valores por defecto.
  const EstadoConsumos({
// Por defecto, lista vacía.
    this.consumos = const [],
// Por defecto, sin error (null).
    this.error,
// Por defecto, no está guardando.
    this.guardando = false,
  });

// Lista de consumos (estado compartido).
  final List<Consumo> consumos;
// Mensaje de error o null.
  final String? error;
// true mientras se guarda.
  final bool guardando;
}

// Notifier: ocupa el lugar del ViewModel y administra un EstadoConsumos.
class ConsumosNotifier extends Notifier<EstadoConsumos> {
// Indica que se sobrescribe el método de Notifier.
  @override
// Estado inicial cuando el provider se usa por primera vez.
  EstadoConsumos build() => const EstadoConsumos();

// Acción que llama la vista al tocar "Guardar"; devuelve true si se guardó.
  Future<bool> guardar(String laboratorio, String litrosTexto) async {
// Quita espacios, cambia coma por punto y convierte a double (null si no es número).
    final litros = double.tryParse(litrosTexto.trim().replaceAll(',', '.'));
// Aplica la regla del dominio.
    final motivo = validarLitros(litros);
// Si la regla encontró un problema...
    if (motivo != null) {
// ...reemplaza el estado: conserva los consumos y pone el error (asignar state avisa solo).
      state = EstadoConsumos(consumos: state.consumos, error: motivo);
// ...y responde que no se guardó.
      return false;
    }

// Nuevo estado: mismos consumos, sin error y guardando = true.
    state = EstadoConsumos(consumos: state.consumos, guardando: true);
// Lee (sin suscribirse) el repositorio desde su provider.
    final repo = ref.read(repositorioProvider);
// Guarda el nuevo consumo; litros! afirma que ya no es null.
    await repo.guardar(Consumo(laboratorio: laboratorio, litros: litros!));
// Nuevo estado con la lista actualizada; guardando vuelve a false por defecto.
    state = EstadoConsumos(consumos: await repo.todos());
// Responde que sí se guardó.
    return true;
  }
}

// Provider global que crea el ConsumosNotifier y expone su EstadoConsumos.
final consumosProvider = NotifierProvider<ConsumosNotifier, EstadoConsumos>(
// Referencia al constructor del Notifier.
  ConsumosNotifier.new,
);

// Widget raíz de la variante riverpod (el ProviderScope está en main_riverpod.dart).
class AppRiverpod extends StatelessWidget {
// Constructor const.
  const AppRiverpod({super.key});

// Indica que se sobrescribe el método de StatelessWidget.
  @override
// Dibuja la app.
  Widget build(BuildContext context) {
// Configuración general de la app Material.
    return MaterialApp(
// Tema con colores generados a partir del verde azulado.
      theme: ThemeData(colorSchemeSeed: Colors.teal),
// Pantalla inicial: las dos pestañas.
      home: const DosPantallas(
// Título de la variante.
        titulo: 'B · riverpod',
// Pestaña Registro: no recibe nada, lee el provider por sí misma.
        registro: RegistroRiverpod(),
// Pestaña Historial: no recibe nada, lee el provider por sí misma.
        historial: HistorialRiverpod(),
      ),
    );
  }
}

// Adaptador de Registro para riverpod; ConsumerWidget da acceso a ref.
class RegistroRiverpod extends ConsumerWidget {
// Constructor const.
  const RegistroRiverpod({super.key});

// Indica que se sobrescribe el método de ConsumerWidget.
  @override
// build recibe además ref para leer providers.
  Widget build(BuildContext context, WidgetRef ref) {
// Lee el estado y se suscribe: se redibuja cada vez que cambie state.
    final estado = ref.watch(consumosProvider);
// Formulario compartido.
    return FormularioRegistro(
// Toma el Notifier (sin suscribirse) y pasa su método guardar.
      alGuardar: ref.read(consumosProvider.notifier).guardar,
// Pasa el error actual.
      error: estado.error,
// Pasa si está guardando.
      guardando: estado.guardando,
    );
  }
}

// Adaptador de Historial para riverpod.
class HistorialRiverpod extends ConsumerWidget {
// Constructor const.
  const HistorialRiverpod({super.key});

// Indica que se sobrescribe el método de ConsumerWidget.
  @override
// build recibe además ref para leer providers.
  Widget build(BuildContext context, WidgetRef ref) {
// Se suscribe al estado y toma solo la lista de consumos.
    final consumos = ref.watch(consumosProvider).consumos;
// Lista compartida.
    return ListaHistorial(consumos: consumos);
  }
}