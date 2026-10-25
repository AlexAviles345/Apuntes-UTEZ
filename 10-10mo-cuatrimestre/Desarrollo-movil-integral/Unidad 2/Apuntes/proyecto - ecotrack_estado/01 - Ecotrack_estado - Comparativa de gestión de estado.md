# Ecotrack_estado — Comparativa de Gestión de Estado

Esta guía compara las tres variantes de [`ecotrack_estado`](ecotrack_estado/) a partir de su código: **ChangeNotifier manual**, **Provider sobre ChangeNotifier** y **Riverpod con Notifier**. Explica qué cambia, qué comparten, sus ventajas y sus costos de uso.

Guías para profundizar: [ChangeNotifier y Observer](02%20-%20Ecotrack_estado%20-%20ChangeNotifier%20y%20Observer.md), [Provider e inyección](03%20-%20Ecotrack_estado%20-%20Provider%20e%20inyecci%C3%B3n%20de%20dependencias.md), [Riverpod y Notifier](04%20-%20Ecotrack_estado%20-%20Riverpod%20y%20Notifier.md) y [Pruebas](06%20-%20Ecotrack_estado%20-%20Pruebas%20de%20las%20tres%20variantes.md).

---

## Primero: Patrón, Herramienta y Arquitectura

Los nombres no representan tres patrones de diseño del mismo tipo:

| Concepto | Qué significa | Dónde aparece |
|---|---|---|
| Observer | Un objeto comunica cambios a quienes lo escuchan | ChangeNotifier y la escucha de sus notificaciones |
| ChangeNotifier | Herramienta de Flutter para emitir avisos de cambio | El ViewModel de las variantes manual y Provider |
| Provider | Biblioteca para suministrar objetos y conectar sus cambios con widgets del árbol | La segunda variante, utilizando el mismo ChangeNotifier |
| Riverpod | Biblioteca para suministrar dependencias y administrar estado mediante providers y contenedores | La tercera variante, con `Notifier<EstadoConsumos>` |
| Repository | Contrato que separa las operaciones de almacenamiento de su implementación concreta | Las tres variantes |
| Separación de estilo MVVM | La vista delega acciones a un gestor de presentación que coordina dominio y datos | ViewModel en las dos primeras y Notifier con ese papel en la tercera |

**ChangeNotifier y Observer describen la herramienta y el patrón que permite aplicar. Provider y ChangeNotifier trabajan juntos en la segunda variante.** Riverpod utiliza su propio Notifier y un objeto que representa el estado.

La documentación de Flutter describe a ChangeNotifier como un objeto que puede ser observado por widgets que escuchan un `Listenable`. [API de ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html).

---

## Qué Permanece Igual

Las tres implementaciones resuelven el mismo problema: capturar consumo de agua y verlo en un historial con su total.

| Pieza compartida | Responsabilidad |
|---|---|
| [`Consumo`](ecotrack_estado/lib/dominio/consumo.dart) | Representar laboratorio y litros |
| `validarLitros` | Aplicar las restricciones del dominio |
| [`ConsumoRepository`](ecotrack_estado/lib/datos/consumo_repository.dart) | Definir `guardar` y `todos` |
| `MemoriaConsumoRepository` | Conservar registros en una lista durante la vida de la instancia |
| [`FormularioRegistro`](ecotrack_estado/lib/presentacion/vistas.dart) | Capturar texto y llamar al callback `alGuardar` |
| `ListaHistorial` | Representar los consumos y calcular la suma |
| `DosPantallas` | Cambiar entre las pestañas Registro e Historial |

También conservan el estado local del formulario y de la pestaña con `State`, `TextEditingController` y `setState`. Adoptar Provider o Riverpod no elimina ese estado local.

Para valores finitos, el dominio de **este proyecto** acepta `0 < litros <= 10000`. Las variantes no cambian la regla al cambiar el mecanismo de estado.

---

## Comparación de las Piezas Principales

| Aspecto | ChangeNotifier manual | Provider | Riverpod |
|---|---|---|---|
| Entrada | [`main.dart`](ecotrack_estado/lib/main.dart) | [`main_provider.dart`](ecotrack_estado/lib/main_provider.dart) | [`main_riverpod.dart`](ecotrack_estado/lib/main_riverpod.dart) |
| Implementación | [`a_change_notifier.dart`](ecotrack_estado/lib/variantes/a_change_notifier.dart) | [`b_provider.dart`](ecotrack_estado/lib/variantes/b_provider.dart) | [`b_riverpod.dart`](ecotrack_estado/lib/variantes/b_riverpod.dart) |
| Gestor | `ConsumosViewModel` | El mismo `ConsumosViewModel` | `ConsumosNotifier` |
| Representación del estado | Campos del ViewModel | Los mismos campos | `EstadoConsumos` |
| Cambio de estado | Asignar campos y avisar | Asignar campos y avisar | Asignar otro objeto a `state` |
| Publicación | `notifyListeners()` | `notifyListeners()` y propagación de Provider | Setter `state` del Notifier |
| Escucha desde widgets | `ListenableBuilder` | `context.watch` | `ref.watch` |
| Entrega del gestor | Constructor `vm:` | Proveedor por encima de los widgets consumidores | `NotifierProvider` dentro de un `ProviderScope` |
| Acceso al repositorio | Constructor del ViewModel | Constructor del ViewModel | `ref.read(repositorioProvider)` |
| Elección de la implementación concreta | `main()` en `main.dart` | `main()` en `main_provider.dart` | Fábrica de `repositorioProvider` en `b_riverpod.dart` |
| Liberación del gestor | `dispose` del `State` que lo creó | La administra `ChangeNotifierProvider(create: ...)` | La administra el entorno de providers de Riverpod |
| Dependencia del mecanismo | SDK de Flutter | Paquete `provider` y SDK de Flutter | Paquete `flutter_riverpod` y SDK de Flutter |

El [`pubspec.yaml`](ecotrack_estado/pubspec.yaml) contiene las dos bibliotecas externas porque las variantes conviven en el mismo proyecto. Ejecutar la variante manual no elimina esas declaraciones del archivo.

---

## El Mismo Guardado, Tres Formas de Actualizar la Vista

En las tres variantes, la acción de guardado sigue este proceso:

```text
Formulario captura texto
    → callback del gestor
    → convertir texto y validar en el dominio
    → indicar guardado en curso
    → esperar guardar(consumo)
    → consultar todos()
    → publicar la lista actualizada
    → devolver true al formulario
```

El formulario limpia el campo y muestra el SnackBar cuando recibe `true` y sigue montado. Si la validación falla, el gestor publica el error y devuelve `false` sin guardar.

### ChangeNotifier manual

```text
ConsumosViewModel cambia campos
    → notifyListeners()
    → ListenableBuilder de cada adaptador
    → FormularioRegistro y ListaHistorial reciben los nuevos valores
```

La conexión es visible en los constructores y en `listenable: vm`. El propietario conserva un ViewModel y pasa la misma referencia a las dos vistas adaptadoras.

### Provider

```text
ConsumosViewModel cambia campos
    → notifyListeners()
    → ChangeNotifierProvider recibe el aviso
    → widgets con context.watch reconstruyen
    → las vistas compartidas reciben los nuevos valores
```

El ViewModel y sus reglas son los mismos. Provider evita entregarlo por cada constructor intermedio y administra el objeto creado mediante `create`. [Documentación de provider](https://pub.dev/packages/provider/versions/6.1.5%2B1).

### Riverpod

```text
ConsumosNotifier crea otro EstadoConsumos
    → state = nuevoEstado
    → consumosProvider publica el cambio
    → widgets con ref.watch reconstruyen
    → las vistas compartidas reciben los nuevos valores
```

La vista observa `EstadoConsumos`; cuando necesita una acción, obtiene `ConsumosNotifier` con `consumosProvider.notifier`. Los valores están almacenados en el contenedor del ámbito, aunque las definiciones de los providers sean globales. [Ámbitos y contenedores de Riverpod](https://riverpod.dev/docs/concepts2/containers).

---

## Ventajas y Desventajas de ChangeNotifier Manual

### Ventajas

- **Hace explícita la entrega de objetos:** los constructores muestran quién recibe el ViewModel.
- **Permite estudiar Observer directamente:** se identifican el objeto observado, el aviso y el widget que escucha.
- **Su mecanismo viene con Flutter:** no necesita una biblioteca externa para conectar estas dos pantallas.
- **Facilita sustituir el repositorio:** la aplicación recibe el contrato por constructor.

### Desventajas y responsabilidades

- Hay que pasar el ViewModel manualmente a cada componente que lo necesite, incluyendo posibles widgets intermedios.
- El propietario debe construirlo una sola vez por ciclo de vida y llamar a `dispose` al terminar.
- Una asignación a un campo sin `notifyListeners()` puede dejar la interfaz sin actualizar.
- Los campos del ViewModel son públicos y mutables en este ejemplo; modificarlos fuera de la acción puede saltarse su coordinación.

Es una opción clara para estudiar el mecanismo y para un árbol pequeño con pocas dependencias compartidas. Ese juicio se basa en la estructura concreta del ejemplo, no en una medición de rendimiento.

---

## Ventajas y Desventajas de Provider

### Ventajas

- **Reutiliza el ViewModel existente:** migrar desde la variante manual no exige reescribir la validación ni el guardado.
- **Reduce el paso de parámetros intermedios:** las vistas adaptadoras obtienen el objeto desde el ámbito del árbol.
- **Administra el ciclo de vida del objeto creado:** `AppProvider` puede ser `StatelessWidget`.
- **Conserva una sustitución sencilla en las pruebas:** se entrega otro repositorio al constructor de `AppProvider`.

### Desventajas y responsabilidades

- Agrega una biblioteca y conceptos de ámbito, creación y consumo.
- El consumidor debe estar debajo del proveedor correcto; su constructor ya no muestra por sí solo qué objeto obtiene del árbol.
- Mantiene el estado mutable y la necesidad de `notifyListeners`, porque sigue utilizando ChangeNotifier.
- En la implementación actual, `watch` escucha al ViewModel completo. Leer después `.consumos` no constituye una selección de cambios.

En este proyecto es la transición con menos cambios desde la variante manual: cambia principalmente cómo se entrega y se escucha el mismo objeto. No significa que Provider convierta automáticamente el estado en inmutable o agregue persistencia.

---

## Ventajas y Desventajas de Riverpod

### Ventajas

- **Distingue el gestor del estado publicado:** la interfaz observa `EstadoConsumos` y obtiene el Notifier para invocar acciones.
- **Expresa cada actualización con un nuevo valor de estado:** puede verse qué lista, error y bandera se publican juntos.
- **Permite reemplazar dependencias por ámbito:** las pruebas utilizan `overrideWithValue` sin editar las vistas.
- **El gestor accede a otros providers mediante `ref`:** no necesita un `BuildContext` del árbol para leer el repositorio.

### Desventajas y responsabilidades

- Introduce más conceptos: provider, contenedor, `ProviderScope`, `ConsumerWidget`, `Notifier`, `state`, `watch`, `read` y overrides.
- La dependencia del repositorio se obtiene mediante `ref.read`, por lo que hay que seguir esa lectura para identificar la fuente efectiva.
- Los cambios de estado deben conservar explícitamente lo necesario. El constructor actual restablece a sus valores por defecto los campos que no se suministran.
- Un campo `final List<Consumo>` no garantiza inmutabilidad profunda: la clase de estado no protege cualquier lista mutable que pudiera recibir.

En la versión actual, la lista inicial es constante y la implementación en memoria devuelve una lista no modificable. Aun así, esa protección no está impuesta por el constructor de `EstadoConsumos`.

Riverpod permite separar lectura y escucha mediante `ref.read` y `ref.watch`; usar una u otra debe corresponder a si se necesita reaccionar a futuros cambios. [Operaciones de Ref](https://riverpod.dev/docs/concepts2/refs).

---

## Cómo Comparar la Dirección de Dependencias

En todas las variantes, las vistas compartidas importan Flutter y el dominio. Reciben datos y callbacks; no consultan directamente al repositorio.

| Componente | Dependencias relevantes |
|---|---|
| Dominio | No importa presentación ni las bibliotecas de estado |
| Datos | Importa `Consumo` del dominio |
| ViewModel de A y Provider | Importa el contrato desde datos, dominio y `ChangeNotifier` de Flutter |
| Adaptadores manuales | Conocen el ViewModel y `ListenableBuilder` |
| Adaptadores de Provider | Conocen el ViewModel y el paquete `provider` |
| Módulo Riverpod | Conoce dominio, datos, vistas y `flutter_riverpod`; contiene tanto los providers como el Notifier |

El contrato de repositorio está físicamente en `datos/consumo_repository.dart` junto a la implementación. No se debe dibujar como si el código lo importara de una interfaz ubicada en dominio.

La dirección de los imports es una propiedad del código. Las llamadas hacia el repositorio y los avisos hacia la interfaz son el flujo de ejecución; no invierten los imports.

---

## Pruebas y Sustitución de Dependencias

| Operación | ChangeNotifier manual | Provider | Riverpod |
|---|---|---|---|
| Construir con otra fuente | `AppChangeNotifier(repositorio: espia)` | `AppProvider(repositorio: espia)` | `repositorioProvider.overrideWithValue(espia)` |
| Crear estado aislado por caso | Nuevo repositorio y nuevo estado de la app | Nuevo repositorio y proveedor | Nuevo `ProviderScope` con su repositorio |
| Verificar resultado visible | Mismo total en el historial | Mismo total en el historial | Mismo total en el historial |

Las nueve pruebas existentes repiten los mismos tres criterios: dato compartido, sustitución y propagación de un error del dominio. Las tres variantes pasan esos casos.

Eso demuestra equivalencia para los escenarios comprobados. No demuestra que tengan idéntico rendimiento, que su arquitectura esté verificada automáticamente o que cubran todas las situaciones de error. La [guía de pruebas](06%20-%20Ecotrack_estado%20-%20Pruebas%20de%20las%20tres%20variantes.md) explica el alcance de cada assertion.

---

## Problemas que Ninguna Variante Resuelve por Sí Sola

Cambiar la biblioteca de estado no cambia automáticamente estas características del código:

- Los registros siguen guardándose en memoria y se pierden al crear una nueva instancia del repositorio.
- El gestor empieza con la lista vacía y no implementa carga inicial desde una fuente previamente poblada.
- El guardado no tiene una ruta completa de recuperación de excepciones del repositorio.
- No se garantiza restaurar `guardando` si una operación lanza una excepción.
- El total sigue calculándose a partir de la lista; no se necesita convertirlo en otra fuente independiente de estado.
- Los adaptadores observan el gestor o estado completo: no se han implementado filtros `select` en estas variantes.

Tampoco hay mediciones de velocidad o memoria que permitan afirmar que una variante sea más rápida en esta aplicación.

---

## Cómo Elegir Según lo que Se Quiere Aprender o Mantener

Estas orientaciones son una valoración del ejemplo, no una regla universal:

| Situación | Variante que conviene estudiar primero | Motivo |
|---|---|---|
| Entender cómo un cambio llega a una vista | ChangeNotifier manual | La relación entre instancia, listener y aviso queda visible |
| Mantener el ViewModel y reducir parámetros por el árbol | Provider | Cambia la distribución del mismo objeto |
| Separar acciones de un valor de estado y practicar overrides | Riverpod | Notifier, estado y providers tienen papeles diferentes |
| Añadir persistencia | Cualquiera, mediante otra implementación de `ConsumoRepository` | Es una responsabilidad del almacenamiento, no de la biblioteca de estado |
| Mejorar el manejo de excepciones | Revisar el flujo de guardado de cualquiera de las tres | Ninguna biblioteca agrega por sí sola la lógica que falta en la acción |

Para este ejemplo pequeño, las tres resuelven los criterios probados. El costo principal que se compara es la cantidad de conceptos y la forma de conectar dependencias y cambios.

## Preguntas para Explicar la Comparativa

1. ¿Por qué ChangeNotifier y Observer pueden aparecer juntos en el nombre de una guía?
2. ¿Qué parte cambia entre la variante manual y Provider si ambas usan el mismo ViewModel?
3. ¿Qué pieza ocupa el papel del ViewModel en Riverpod?
4. ¿Qué diferencia existe entre observar estado y obtener el objeto que contiene las acciones?
5. ¿Quién crea y quién libera el gestor en cada variante?
6. ¿Dónde se elige el repositorio concreto en cada entrada?
7. ¿Por qué cambiar de gestor de estado no agrega una base de datos?
8. ¿Qué demuestran los nueve casos existentes y qué no permiten concluir?

[Volver al índice de Ecotrack_estado](README.md).
