// PRESENTACIÓN — widgets "tontos", compartidos por las tres variantes.
// Reciben datos y callbacks. No saben qué gestor de estado hay arriba.
// Así la comparación se limita a la parte que de verdad cambia: el cableado.

// Importa los widgets de Material Design.
import 'package:flutter/material.dart';

// Importa Consumo y la lista laboratoriosUtez.
import '../dominio/consumo.dart';

// Formulario para capturar un consumo; es StatefulWidget porque guarda estado local.
class FormularioRegistro extends StatefulWidget {
  // Constructor: todo lo que necesita llega desde fuera.
  const FormularioRegistro({
    // Clave opcional del widget, se pasa al padre.
    super.key,
    // Función que se llama al tocar "Guardar".
    required this.alGuardar,
    // Mensaje de error a mostrar bajo el campo de litros.
    required this.error,
    // Indica si hay un guardado en curso.
    required this.guardando,
  });

  // Callback que recibe laboratorio y litros (como texto) y responde si se guardó.
  final Future<bool> Function(String laboratorio, String litros) alGuardar;
  // Error actual o null.
  final String? error;
  // true mientras se guarda.
  final bool guardando;

  // Indica que se sobrescribe el método de StatefulWidget.
  @override
  // Crea el objeto State que guarda el estado local del formulario.
  State<FormularioRegistro> createState() => _FormularioRegistroState();
}

// Estado local del formulario.
class _FormularioRegistroState extends State<FormularioRegistro> {
  // Controlador del campo de texto de litros (estado efímero).
  final _litros = TextEditingController();
  // Laboratorio seleccionado; inicia con el primero de la lista (estado efímero).
  String _laboratorio = laboratoriosUtez.first;

  // Indica que se sobrescribe el método de State.
  @override
  // Se llama cuando el widget sale del árbol.
  void dispose() {
    // Libera el controlador para no dejar memoria ocupada.
    _litros.dispose();
    // Completa la limpieza de la clase padre.
    super.dispose();
  }

  // Lógica del botón "Guardar".
  Future<void> _guardar() async {
    // Llama al callback del gestor con el laboratorio y el texto escrito; espera el resultado.
    final ok = await widget.alGuardar(_laboratorio, _litros.text);
    // Si no se guardó o el widget ya no está en pantalla, no hace nada más.
    if (!ok || !mounted) return;
    // Limpia el campo de litros.
    _litros.clear();
    // Busca el ScaffoldMessenger más cercano...
    ScaffoldMessenger.of(context)
        // ...y muestra un aviso temporal en la parte inferior.
        .showSnackBar(const SnackBar(content: Text('Consumo guardado')));
  }

  // Indica que se sobrescribe el método de State.
  @override
  // Dibuja el formulario.
  Widget build(BuildContext context) {
    // Lista desplazable con los campos del formulario.
    return ListView(
      // Margen interno de 16 en todos los lados.
      padding: const EdgeInsets.all(16),
      // Elementos del formulario, de arriba hacia abajo.
      children: [
        // Selector desplegable de laboratorio.
        DropdownButtonFormField<String>(
          // Valor seleccionado al inicio.
          initialValue: _laboratorio,
          // Etiqueta que se muestra en el campo.
          decoration: const InputDecoration(labelText: 'Laboratorio'),
          // Opciones del desplegable.
          items: [
            // Recorre los laboratorios...
            for (final lab in laboratoriosUtez)
              // ...y crea una opción por cada uno.
              DropdownMenuItem(value: lab, child: Text(lab)),
          ],
          // Al elegir otro, se guarda en el estado local y se redibuja con setState.
          onChanged: (lab) => setState(() => _laboratorio = lab!),
        ),
        // Campo para escribir los litros.
        TextField(
          // Clave para encontrar este campo en los tests.
          key: const Key('litros'),
          // Conecta el campo con su controlador.
          controller: _litros,
          // Muestra el teclado numérico en el celular.
          keyboardType: TextInputType.number,
          // Apariencia del campo.
          decoration: InputDecoration(
            // Etiqueta del campo.
            labelText: 'Litros',
            // Muestra el error que llega del gestor (si es null no muestra nada).
            errorText: widget.error,
          ),
        ),
        // Espacio vertical de 16 entre el campo y el botón.
        const SizedBox(height: 16),
        // Botón principal.
        FilledButton(
          // Si está guardando, null desactiva el botón; si no, llama a _guardar.
          onPressed: widget.guardando ? null : _guardar,
          // Texto del botón.
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// Lista de consumos con el total; StatelessWidget porque no guarda nada propio.
class ListaHistorial extends StatelessWidget {
  // Constructor: recibe la lista de consumos a mostrar.
  const ListaHistorial({super.key, required this.consumos});

  // Consumos que llegan del gestor de estado.
  final List<Consumo> consumos;

  // Indica que se sobrescribe el método de StatelessWidget.
  @override
  // Dibuja el historial.
  Widget build(BuildContext context) {
    // Si todavía no hay consumos...
    if (consumos.isEmpty) {
      // ...muestra un mensaje centrado.
      return const Center(child: Text('Sin consumos'));
    }
    // Estado derivado: suma los litros de todos los consumos (no se guarda, se calcula).
    final total = consumos.fold<double>(0, (s, c) => s + c.litros);
    // Lista desplazable con el total y los consumos.
    return ListView(
      // Filas de la lista.
      children: [
        // Primera fila: el total.
        ListTile(
          // Texto del total con un decimal.
          title: Text('Total: ${total.toStringAsFixed(1)} L'),
          // Color de fondo tomado del tema para distinguir la fila.
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        // Recorre cada consumo...
        for (final c in consumos)
          // ...y crea una fila para él.
          ListTile(
            // Icono de gota a la izquierda.
            leading: const Icon(Icons.water_drop),
            // Litros como texto principal.
            title: Text('${c.litros} L'),
            // Laboratorio como texto secundario.
            subtitle: Text(c.laboratorio),
          ),
      ],
    );
  }
}

/// Dos pestañas: Registro e Historial. Es el escenario del criterio
/// "Dato compartido": lo que se guarda en una debe verse en la otra.
class DosPantallas extends StatefulWidget {
  // Constructor: recibe el título y las dos vistas ya cableadas a su gestor.
  const DosPantallas({
    // Clave opcional del widget.
    super.key,
    // Texto de la barra superior (nombre de la variante).
    required this.titulo,
    // Widget de la pestaña Registro.
    required this.registro,
    // Widget de la pestaña Historial.
    required this.historial,
  });

  // Título de la AppBar.
  final String titulo;
  // Vista de registro.
  final Widget registro;
  // Vista de historial.
  final Widget historial;

  // Indica que se sobrescribe el método de StatefulWidget.
  @override
  // Crea el State que guarda la pestaña activa.
  State<DosPantallas> createState() => _DosPantallasState();
}

// Estado local de DosPantallas.
class _DosPantallasState extends State<DosPantallas> {
  // Pestaña activa: 0 = Registro, 1 = Historial (estado efímero).
  int _indice = 0;

  // Indica que se sobrescribe el método de State.
  @override
  // Dibuja la estructura de la pantalla.
  Widget build(BuildContext context) {
    // Estructura base de Material: barra superior, cuerpo y barra inferior.
    return Scaffold(
      // Barra superior con el título de la variante.
      appBar: AppBar(title: Text(widget.titulo)),
      // IndexedStack mantiene montadas las dos vistas y solo muestra una.
      body: IndexedStack(
        // Cuál de los hijos se muestra.
        index: _indice,
        // Las dos vistas: posición 0 Registro, posición 1 Historial.
        children: [widget.registro, widget.historial],
      ),
      // Barra de navegación inferior.
      bottomNavigationBar: NavigationBar(
        // Resalta la pestaña activa.
        selectedIndex: _indice,
        // Al tocar una pestaña, guarda su índice y redibuja.
        onDestinationSelected: (i) => setState(() => _indice = i),
        // Botones de la barra.
        destinations: const [
          // Pestaña 0: Registro.
          NavigationDestination(icon: Icon(Icons.add), label: 'Registro'),
          // Pestaña 1: Historial.
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}
