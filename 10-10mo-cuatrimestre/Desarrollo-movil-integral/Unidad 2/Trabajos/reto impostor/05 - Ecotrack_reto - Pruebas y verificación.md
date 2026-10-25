# Ecotrack_reto — Pruebas y Verificación

El reto combina dos comprobaciones: **que las operaciones funcionen** y **que sus responsabilidades estén separadas**. La suite entregada contiene 25 pruebas; el script revisa archivos e indicios de dependencias. La lectura del código y de los contratos completa esa verificación.

## Dependencias Utilizadas

El [`pubspec.yaml` final](proyectos/ecotrack_reto%20-%20final/pubspec.yaml) conserva las declaraciones del proyecto original:

```yaml
environment:
  sdk: ^3.13.3

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

| Dependencia o archivo | Función |
|---|---|
| `flutter_test` | Entorno de pruebas, `test`, `group`, `setUp`, `expect`, matchers y herramientas de widgets |
| `flutter_lints` | Reglas de análisis estático; no sustituye la ejecución de las pruebas |
| `analysis_options.yaml` | Incluye las reglas de `flutter_lints` y excluye directorios de plataformas y compilación |
| `pubspec.lock` | Registra las versiones resueltas para reproducir las dependencias de la aplicación |

No se añadieron Mockito, Mocktail, Provider, Riverpod o `integration_test`. El repositorio espía de la etapa 3 está escrito directamente en la prueba mediante el contrato de la aplicación.

## Etapa 1: Dominio — 9 Pruebas

Archivo: [`etapa1_dominio_test.dart`](proyectos/ecotrack_reto%20-%20final/test/etapa1_dominio_test.dart).

Las pruebas crean entidades con una fecha fija y llaman a `ReglaConsumo.validar(..., hoy: hoy)`:

1. La entidad conserva laboratorio, litros y fecha.
2. El catálogo contiene los tres laboratorios esperados.
3. El tope es `10000`.
4. Un consumo en rango es aceptado.
5. Exactamente el tope es aceptado.
6. Un laboratorio vacío se rechaza con su mensaje.
7. Cero o un valor negativo se rechazan.
8. Un valor mayor que el tope se rechaza.
9. Una fecha futura se rechaza.

Son pruebas unitarias sin interfaz. Recibir `hoy` evita que el resultado cambie con la fecha real de ejecución. Un `test` puede contener varios `expect`; sigue contando como un solo caso.

## Etapa 2: Datos — 5 Pruebas

Archivo: [`etapa2_datos_test.dart`](proyectos/ecotrack_reto%20-%20final/test/etapa2_datos_test.dart).

| Caso | Qué comprueba |
|---|---|
| Memoria cumple el contrato | La implementación es un `ConsumoRepository` |
| Memoria guarda y filtra | Al guardar Química y Redes, consultar Química devuelve solo su consumo |
| Servicio recibe y devuelve mapas | Se puede enviar una lectura de Física y recuperarla |
| Nube cumple el mismo contrato | La implementación también es un `ConsumoRepository` |
| Nube conserva datos en la traducción | Laboratorio, litros y fecha sobreviven al paso por el servicio |

Estas pruebas utilizan el servicio simulado real del proyecto, con sus demoras, sin conexión externa. La última prueba comprueba el resultado de la traducción; por sí sola no demuestra en qué archivo se implementó.

## Etapa 3: ViewModel — 8 Pruebas

Archivo: [`etapa3_viewmodel_test.dart`](proyectos/ecotrack_reto%20-%20final/test/etapa3_viewmodel_test.dart).

`RepositorioEspia implements ConsumoRepository` conserva una lista de consumos recibidos. Permite comprobar si el ViewModel llamó al almacenamiento. `setUp` crea un espía y un ViewModel nuevos para cada caso:

```dart
vm = RegistroViewModel(repo, reloj: () => hoy);
```

Los ocho casos comprueban:

1. Estado inicial: primer laboratorio, sin error, sin carga y sin historial.
2. Guardado válido, fecha obtenida del reloj e historial actualizado.
3. Coma decimal interpretada correctamente.
4. Rechazo de litros inválidos sin llamar al guardado del repositorio.
5. Rechazo de texto no numérico.
6. Emisión de al menos una notificación al guardar.
7. Cambio de laboratorio, filtrado y limpieza del error.
8. Suma de los litros del historial actual.

No se montan widgets. El listener que incrementa un contador comprueba que hubo avisos; no impone un número exacto ni una secuencia completa de estados intermedios.

## Etapa 4: Aplicación — 3 Pruebas de Widgets

Archivo: [`etapa4_app_test.dart`](proyectos/ecotrack_reto%20-%20final/test/etapa4_app_test.dart).

Cada caso construye `EcoTrackApp(repositorio: MemoriaConsumoRepository())`. La prueba sustituye la composición de `main()` y entrega la implementación directamente.

| Caso | Acción y resultado |
|---|---|
| Arranque vacío | Aparecen el título, `Sin consumos todavía` y total `0.0 L` de Química |
| Guardado válido | Escribir `12.5`, pulsar `Guardar`, ver confirmación, elemento y total |
| Cero litros | Escribir `0`, ver el motivo de rechazo y conservar el historial vacío |

El campo se localiza mediante `Key('campoLitros')`. `pumpWidget` monta la aplicación; `enterText` y `tap` simulan acciones; `pumpAndSettle` procesa los frames hasta que la interfaz se estabiliza. Los finders buscan los textos y los matchers verifican cuántos aparecen. [Introducción oficial a pruebas de widgets](https://docs.flutter.dev/cookbook/testing/widget/introduction).

Son pruebas de widgets con componentes reales de la aplicación. No son pruebas sobre un dispositivo físico y estos tres casos usan memoria, no nube.

## Qué Revisa `verificar_capas.sh`

El [`script original conservado en la solución`](proyectos/ecotrack_reto%20-%20final/verificar_capas.sh) revisa:

1. Existencia de los nueve archivos del contrato.
2. Ausencia de imports de Flutter en dominio.
3. Ausencia de `material.dart` y de nombres de implementaciones concretas en el ViewModel.
4. Ausencia de imports de datos en la vista.
5. Referencias al servicio limitadas a los lugares permitidos.
6. Presencia de `usarNube` en `main.dart`.

Sus verificaciones son búsquedas de texto, no un análisis completo del lenguaje. **Todo OK y 25 pruebas aprobadas no bastan para demostrar que se cumplieron todas las instrucciones.**

Durante esta revisión, la separación recibida ya pasaba ambas comprobaciones después de regenerar sus dependencias locales. Sin embargo, `Consumo` contenía JSON, `hoy` era opcional y había cambios en la interacción de la vista. Esas diferencias se encontraron comparando el código con el original y con los contratos escritos, y se corrigieron en la solución.

También se comprobó directamente que datos no importa Flutter, que la regla no consulta el reloj, que no existe traducción JSON en la entidad y que las reglas de negocio no están repetidas en vista o ViewModel.

## Comparación Adicional con el Original

Se ejecutaron cuatro verificaciones temporales fuera de `test/`, sin alterar la suite entregada:

| Verificación | Alcance |
|---|---|
| Recorrido con memoria | Comparar textos visibles, entrada, estados habilitados y rectángulos de campo y botón |
| Mismo recorrido con nube | Comparar los mismos resultados utilizando la simulación remota |
| Tiempos de carga | Contrastar los estados antes de `600 ms`, durante la lectura y al completar `1000 ms` |
| Cambio durante el guardado | Reproducir la diferencia de laboratorio capturado descrita en la guía de arquitectura |

Los recorridos incluyeron texto inválido, cero, negativos, exceso del tope, coma decimal, varios guardados, exactamente el tope y cambio entre los tres laboratorios. La comparación omite la hora concreta de los registros, porque ambos recorridos consultan el reloj real por separado. No fue una comparación de capturas píxel por píxel.

Para contrastar la nube original se utilizó una copia temporal de su archivo con su bandera activada; el proyecto original permaneció intacto. Los archivos temporales se retiraron al terminar. Las cuatro verificaciones pasaron, incluida la comprobación explícita de la diferencia de concurrencia; esa última no afirma que ambos resultados sean iguales.

## Comandos de Verificación

Desde la carpeta del trabajo, entre a la solución:

```bash
cd "proyectos/ecotrack_reto - final"
flutter pub get
flutter test -r expanded
bash verificar_capas.sh
flutter analyze
```

Para estudiar cada etapa por separado:

```bash
flutter test test/etapa1_dominio_test.dart -r expanded
flutter test test/etapa2_datos_test.dart -r expanded
flutter test test/etapa3_viewmodel_test.dart -r expanded
flutter test test/etapa4_app_test.dart -r expanded
```

El original se ejecuta con `flutter run -t lib/main_mezclado.dart`; la solución, con `flutter run`. En la solución, cambiar `usarNube` a `true` y reiniciar aplica la composición de nube. Ese cambio se hace únicamente en `lib/main.dart`.

Si un proyecto fue copiado desde otro equipo, ejecute `flutter pub get` antes de probarlo. `.dart_tool/package_config.json` contiene rutas locales y no debe reutilizarse como configuración portable.

## Revisión de `.gitignore` en Ambos Proyectos

Las reglas existentes son adecuadas para los archivos presentes. Se revisaron los `.gitignore` de raíz y de Android, iOS y macOS de ambos proyectos, sin modificar el original.

| Se excluye | Ejemplos |
|---|---|
| Dependencias y configuración generada | `.dart_tool/`, `.pub/`, `.pub-cache/`, `.flutter-plugins-dependencies` |
| Compilación y cobertura | `build/`, `coverage/`, salidas de Android y archivos de símbolos |
| Configuración local de IDE | `.idea/` y archivos `*.iml` |
| Configuración local de Android | `local.properties`, `.gradle/`, `key.properties` y almacenes de firma |
| Dependencias y archivos generados de Apple | `Pods/`, directorios `ephemeral/`, `Generated.xcconfig` y registrantes generados de iOS |

Se conservan `lib/`, `test/`, `verificar_capas.sh`, `pubspec.yaml`, **`pubspec.lock`**, `.metadata`, los `.gitignore`, recursos y configuración fuente de plataformas.

Se comprobó con Git que 16 rutas representativas de archivos locales o generados se ignoran en cada proyecto, que 12 rutas necesarias permanecen disponibles para versionar y que no hay archivos ya rastreados que coincidan con las exclusiones. No fue necesario cambiar sus reglas.

`.gitignore` afecta a archivos sin seguimiento; no elimina del índice uno que ya estuviera rastreado. [Documentación de gitignore](https://git-scm.com/docs/gitignore).

## Resultado y Alcance

- **25 pruebas originales aprobadas.**
- **Script de capas: todo OK.**
- **Análisis estático de la solución: sin incidencias.**
- **Cuatro verificaciones adicionales completadas**, con la diferencia de concurrencia documentada.
- **Original y archivos de evaluación conservados.**

La comprobación de interfaz se realizó mediante pruebas de widgets; no se afirma una ejecución manual en un dispositivo físico. La nube continúa siendo simulada y las pruebas no cubren una integración con servicios externos.

[Anterior: arquitectura final](04%20-%20Ecotrack_reto%20-%20Arquitectura%20final%20y%20flujos.md) · [Volver a la actividad](01%20-%20Ecotrack_reto%20-%20Actividad%20y%20criterios.md) · [Índice](README.md).
