// PRESENTACIÓN — ViewModel con ChangeNotifier.
// Lo usan la variante A (ChangeNotifier puro) y la variante B con provider.
// provider NO reemplaza esta clase: solo la entrega a las pantallas.

// Importa ChangeNotifier (viene con Flutter, no requiere paquetes extra).
import 'package:flutter/foundation.dart';

// Importa el contrato del repositorio (no la implementación concreta).
import '../datos/consumo_repository.dart';
// Importa Consumo y la regla validarLitros.
import '../dominio/consumo.dart';

// ViewModel: dueño del estado compartido; extiende ChangeNotifier para poder avisar cambios.
class ConsumosViewModel extends ChangeNotifier {
  // Recibe el repositorio desde fuera (inyección de dependencias).
  ConsumosViewModel(this._repositorio);

  // Repositorio privado con el que se guardan y leen los consumos.
  final ConsumoRepository _repositorio;

  // Estado compartido: la lista de consumos que ven Registro e Historial.
  List<Consumo> consumos = [];
  // Estado: mensaje de error de validación (null si no hay error).
  String? error;
  // Estado: true mientras se está guardando (sirve para desactivar el botón).
  bool guardando = false;

  // Acción que llama la vista al tocar "Guardar"; devuelve true si se guardó.
  Future<bool> guardar(String laboratorio, String litrosTexto) async {
    // Quita espacios, cambia coma por punto y convierte el texto a double (null si no es número).
    final litros = double.tryParse(litrosTexto.trim().replaceAll(',', '.'));
    // Aplica la regla del dominio; motivo trae el mensaje de error o null.
    final motivo = validarLitros(litros);
    // Si la regla encontró un problema...
    if (motivo != null) {
      // ...se guarda el mensaje en el estado...
      error = motivo;
      // ...se avisa a quien escucha para que muestre el error...
      notifyListeners();
      // ...y se indica a la vista que no se guardó.
      return false;
    }

    // Marca que empezó el guardado.
    guardando = true;
    // Limpia cualquier error anterior.
    error = null;
    // Avisa: "estoy guardando" (la vista desactiva el botón).
    notifyListeners();

    // Pide al repositorio que guarde el nuevo consumo; litros! afirma que ya no es null.
    await _repositorio.guardar(
      // Crea la entidad con los datos del formulario.
      Consumo(laboratorio: laboratorio, litros: litros!),
    );
    // Vuelve a leer la lista completa desde la fuente de verdad.
    consumos = await _repositorio.todos();

    // Marca que terminó el guardado.
    guardando = false;
    // Avisa: "ya hay consumos nuevos" (Historial se redibuja).
    notifyListeners();
    // Indica a la vista que sí se guardó.
    return true;
  }
}
