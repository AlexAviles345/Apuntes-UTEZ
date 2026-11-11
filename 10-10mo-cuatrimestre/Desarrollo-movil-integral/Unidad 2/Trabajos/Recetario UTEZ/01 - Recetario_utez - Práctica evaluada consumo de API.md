# Práctica evaluada — Recetario UTEZ: consumir una API desde cero

**Material:** carpeta `kit_alumno/` (55 pruebas y un script de verificación).

---

## Actividad

La cafetería de la UTEZ quiere una app para consultar recetas. Vas a construir, **desde un proyecto vacío**, una pantalla en la que:

1. la persona escribe lo que busca (o lo deja vacío para ver recetas en general);
2. toca **Buscar recetas**;
3. el botón se desactiva y aparece un indicador de carga;
4. la app consulta un servicio real por HTTPS;
5. el resultado se muestra en **tarjetas**;
6. si no hay resultados, aparece un mensaje que dice qué se buscó;
7. si algo falla, aparece un mensaje claro y un botón **Reintentar** que repite la misma búsqueda.

El servicio es **DummyJSON Recipes**: público, sin llave y sin datos personales.

```http
GET https://dummyjson.com/recipes?limit=10
GET https://dummyjson.com/recipes/search?q=pasta&limit=10
```

Abre las dos URL en el navegador **antes de empezar** y observa la respuesta:

```json
{
  "recipes": [
    {
      "id": 1,
      "name": "Classic Margherita Pizza",
      "ingredients": ["Pizza dough", "Tomato sauce", "..."],
      "prepTimeMinutes": 20,
      "cookTimeMinutes": 15,
      "servings": 4,
      "difficulty": "Easy",
      "cuisine": "Italian",
      "tags": ["Pizza", "Italian"],
      "rating": 4.6,
      "image": "https://cdn.dummyjson.com/...",
      "...": "otros campos que no usarás"
    }
  ],
  "total": 50,
  "skip": 0,
  "limit": 10
}
```

Fíjate en tres detalles que las pruebas van a revisar:

- `rating` a veces llega como entero (`5`) y a veces con decimales (`4.6`).
- `difficulty` hoy trae `Easy`, `Medium` o `Hard`, pero el servidor podría agregar otros valores.
- Una búsqueda sin resultados **no es un error**: responde 200 con `"recipes": []`.

---

## Lo que vas a demostrar

| Competencia | Dónde se evalúa |
|---|---|
| Modelar datos del dominio en Dart puro | Etapa 1 |
| Convertir JSON en objetos tipados, decidiendo qué es obligatorio y qué se tolera | Etapa 2 |
| Configurar Dio con HTTPS, timeouts e interceptor de bitácora segura | Etapa 3 |
| Distinguir error HTTP de error de red y traducirlos | Etapa 3 |
| Representar carga, datos, vacío y error con estados excluyentes | Etapa 4 |
| Construir la interfaz sin mezclar capas | Etapa 5 |
| Provocar y documentar los escenarios reales con el servicio | Etapa 6 |

---

## Reglas

1. **Trabajo individual.** Puedes consultar la documentación oficial (Flutter, Dart, Dio, DummyJSON) y tus prácticas anteriores. Si usas una herramienta de IA, eres responsable de cada línea: tu docente puede pedirte que expliques cualquier parte de tu código y, si no puedes, esa parte no cuenta.
2. **No edites `test/` ni `verificar_recetario.sh`.** Se revisa con una copia limpia del kit; si una prueba fue modificada, esa etapa vale 0.
3. **Respeta los contratos al pie de la letra:** nombres de archivos, clases, métodos, parámetros, textos y llaves. Las pruebas dependen de ellos. Lo de adentro lo escribes tú.
4. **Haz las etapas en orden** y no avances con pruebas en rojo.
5. **Un commit por etapa**, con el mensaje que se indica. El historial forma parte de la evaluación.

---

## Entregables

1. Enlace a tu repositorio.
2. Dentro del proyecto:
   - el código en `lib/`;
   - el kit sin modificar en `test/` y `verificar_recetario.sh`;
   - `docs/evidencias.md` y al menos 5 imágenes en `docs/capturas/`.
3. Un historial de Git con al menos un commit por etapa.

---

## Cronograma sugerido

| Etapa | Qué | Tiempo |
|---|---|---|
| 0 | Arranque del proyecto y el kit | 15 min |
| 1 | Dominio | 20 min |
| 2 | JSON → Dart | 40 min |
| 3 | Cliente Dio, bitácora, errores y repositorio | 50 min |
| 4 | Mensajes y ViewModel | 35 min |
| 5 | Tarjeta, pantalla y raíz | 40 min |
| 6 | Escenarios reales y evidencias | 30 min |

---

## Etapa 0 — Arranque (15 min)

El proyecto **tiene que llamarse `recetario_utez`**: las pruebas importan `package:recetario_utez/...`.

```bash
flutter create --empty --org mx.edu.utez recetario_utez
cd recetario_utez
flutter pub add dio

# Copia el kit (ajusta la ruta a donde tengas kit_alumno/)
cp -R ../kit_alumno/test .
cp ../kit_alumno/verificar_recetario.sh .

mkdir -p lib/dominio lib/datos lib/presentacion docs/capturas

git init && git add . && git commit -m "chore: proyecto base con kit de pruebas"

flutter test                 # falla: todavía no existe nada
bash verificar_recetario.sh  # casi todo en FALTA
```

En Windows usa **Git Bash** para `cp` y para el script.

Permisos de red:
- **Android** — en `android/app/src/main/AndroidManifest.xml`, justo antes de `<application`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  ```

**Comprueba:** `pubspec.yaml` dice `name: recetario_utez` y tiene `dio` en `dependencies`.

---

## Estructura objetivo

```text
lib/
├── dominio/
│   ├── receta.dart                  Etapa 1
│   └── falla_red.dart               Etapa 1
├── datos/
│   ├── recetas_json.dart            Etapa 2
│   ├── cliente_http.dart            Etapa 3
│   ├── bitacora_interceptor.dart    Etapa 3
│   ├── traducir_error.dart          Etapa 3
│   ├── recetas_repositorio.dart     Etapa 3
│   └── dummyjson_repositorio.dart   Etapa 3
├── presentacion/
│   ├── mensajes.dart                Etapa 4
│   ├── recetas_view_model.dart      Etapa 4
│   ├── tarjeta_receta.dart          Etapa 5
│   └── recetas_pagina.dart          Etapa 5
├── app.dart                         Etapa 5
└── main.dart                        Etapa 5
docs/
├── evidencias.md                    Etapa 6
└── capturas/                        Etapa 6
```

---

## Qué puede importar cada capa

```text
dominio/                   → nada (ni Flutter ni Dio ni JSON)
datos/                     → dominio, dio              (nunca Flutter)
presentacion/              → dominio, datos/recetas_repositorio.dart  (nunca Dio)
vistas (pagina, tarjeta)   → dominio y el ViewModel    (nunca datos/)
app.dart                   → contrato del repositorio y presentación
main.dart                  → todo, solo para armar la app
```

`package:dio` solo se importa dentro de `lib/datos/`. `DummyJsonRepositorio` solo se importa en `main.dart`.

---

## Contratos fijos

Las firmas son obligatorias. Donde dice `{ ... }`, el cuerpo lo escribes tú.

```dart
// lib/dominio/receta.dart
const umbralRapidaMinutos = 30;

enum Dificultad {
  facil('Fácil'),
  media('Media'),
  dificil('Difícil'),
  desconocida('Sin dato');

  const Dificultad(this.etiqueta);
  final String etiqueta;
}

class Receta {
  const Receta({
    required this.id,
    required this.nombre,
    required this.cocina,
    required this.dificultad,
    required this.minutosPreparacion,
    required this.minutosCoccion,
    required this.porciones,
    required this.calificacion,
    this.etiquetas = const [],
    this.ingredientes = const [],
  });
  final int id;
  final String nombre;
  final String cocina;
  final Dificultad dificultad;
  final int minutosPreparacion;
  final int minutosCoccion;
  final int porciones;
  final double calificacion;
  final List<String> etiquetas;
  final List<String> ingredientes;

  int get tiempoTotal { ... }
  bool get esRapida { ... }
}

class PaginaRecetas {
  const PaginaRecetas({required this.recetas, required this.total});
  final List<Receta> recetas;
  final int total;
}

// lib/dominio/falla_red.dart
sealed class FallaRed implements Exception { const FallaRed(); }
final class SinConexion extends FallaRed { const SinConexion(); }
final class TiempoAgotado extends FallaRed { const TiempoAgotado(); }
final class ErrorDelServidor extends FallaRed { const ErrorDelServidor(this.codigo); final int codigo; }
final class PeticionRechazada extends FallaRed { const PeticionRechazada(this.codigo); final int codigo; }
final class RespuestaInvalida extends FallaRed { const RespuestaInvalida(); }

// lib/datos/recetas_json.dart
Dificultad dificultadDesdeTexto(Object? valor) { ... }
Receta recetaDesdeJson(Map<String, dynamic> json) { ... }
PaginaRecetas paginaDesdeJson(Map<String, dynamic> json) { ... }

// lib/datos/cliente_http.dart
const urlDummyJson = 'https://dummyjson.com';
Dio crearDioRecetas({List<Interceptor> interceptores = const []}) { ... }

// lib/datos/bitacora_interceptor.dart
class BitacoraInterceptor extends Interceptor {
  BitacoraInterceptor({void Function(String linea)? escribir});
}

// lib/datos/traducir_error.dart
FallaRed traducirError(DioException e) { ... }

// lib/datos/recetas_repositorio.dart
abstract class RecetasRepositorio {
  Future<PaginaRecetas> buscar({String texto = ''});
}

// lib/datos/dummyjson_repositorio.dart
const recetasPorPagina = 10;
class DummyJsonRepositorio implements RecetasRepositorio {
  DummyJsonRepositorio(Dio dio);
}

// lib/presentacion/mensajes.dart
const mensajeInesperado = 'Algo salió mal. Intenta de nuevo.';
String mensajePara(FallaRed falla) { ... }

// lib/presentacion/recetas_view_model.dart
sealed class EstadoRecetas { const EstadoRecetas(); }
final class RecetasInicial extends EstadoRecetas { const RecetasInicial(); }
final class RecetasCargando extends EstadoRecetas { const RecetasCargando(); }
final class RecetasListas extends EstadoRecetas { const RecetasListas(this.recetas, this.total); final List<Receta> recetas; final int total; }
final class RecetasVacias extends EstadoRecetas { const RecetasVacias(this.busqueda); final String busqueda; }
final class RecetasFallidas extends EstadoRecetas { const RecetasFallidas(this.mensaje); final String mensaje; }

class RecetasViewModel extends ChangeNotifier {
  RecetasViewModel(RecetasRepositorio repositorio);

  EstadoRecetas get estado;       // empieza en RecetasInicial
  bool get cargando;              // derivado del estado
  String get ultimaBusqueda;      // el último texto buscado, ya sin espacios
  int get rapidas;                // derivado: recetas rápidas del resultado; 0 si no hay

  Future<void> buscar(String texto) { ... }
  Future<void> reintentar() { ... }
}

// lib/presentacion/tarjeta_receta.dart
class TarjetaReceta extends StatelessWidget {
  const TarjetaReceta({super.key, required this.receta});
}

// lib/presentacion/recetas_pagina.dart
class RecetasPagina extends StatefulWidget {
  const RecetasPagina({super.key, required this.vm});
}

// lib/app.dart
class AppRecetario extends StatefulWidget {
  const AppRecetario({super.key, required this.repositorio});
}
```

---

## Textos y llaves que buscan las pruebas

| Dónde | Texto o llave exacta |
|---|---|
| `AppBar` | `Recetario UTEZ` |
| Campo de búsqueda | `Key('busqueda')` |
| Botón | `Key('buscar')`, texto `Buscar recetas` |
| Estado inicial | `Escribe una receta o déjalo vacío y toca Buscar recetas.` |
| Vacío, con texto | `No encontramos recetas para "zzz".` (con el texto buscado entre comillas) |
| Vacío, sin texto | `No hay recetas disponibles.` |
| Error | El mensaje de `mensajePara` y un botón `Reintentar` |
| Encabezado de la lista | `Mostrando 3 de 50 recetas · Rápidas: 2` |
| Tarjeta: título | El nombre de la receta |
| Tarjeta: subtítulo | `Italian · Fácil` (cocina, punto medio, etiqueta de la dificultad) |
| Tarjeta: datos | `Tiempo: 35 min · Porciones: 4` |
| Tarjeta: calificación | `Calificación: 4.6` (siempre un decimal) |
| Tarjeta: aviso | `Rápida` (solo si `esRapida`) |

| Falla | Mensaje exacto de `mensajePara` |
|---|---|
| `SinConexion` | `Sin conexión. Revisa tu red e intenta de nuevo.` |
| `TiempoAgotado` | `El recetario tardó demasiado en responder. Intenta de nuevo.` |
| `ErrorDelServidor(503)` | `El recetario no está disponible (503). Intenta más tarde.` |
| `PeticionRechazada(_)` | `No pudimos hacer esa búsqueda. Avisa al equipo de desarrollo.` |
| `RespuestaInvalida` | `Las recetas llegaron con un formato inesperado.` |

| Bitácora | Formato |
|---|---|
| Petición | `→ GET /recipes/search` |
| Respuesta | `← 200 GET /recipes/search (215 ms)` |
| Error | Empieza con `✗` e incluye el código si lo hay: `✗ badResponse 503 GET /recipes (40 ms)` |

---

## Etapa 1 — Dominio (20 min)

**Archivos:** `lib/dominio/receta.dart` y `lib/dominio/falla_red.dart`.

1. Escribe `umbralRapidaMinutos`, el `enum Dificultad`, `Receta` y `PaginaRecetas` como dice el contrato.
2. `tiempoTotal` es la suma de preparación y cocción.
3. `esRapida` es verdadero si el tiempo total es **a lo más** `umbralRapidaMinutos`.
4. Escribe la familia `FallaRed`.

**Pistas:**
- "A lo más" es `<=`. La prueba revisa 30 y 31.
- Un `enum` con campo se declara con un constructor `const` y un campo `final`.
- Este archivo no importa nada. Si te dan ganas de importar `dio` o leer un `Map`, estás en la capa equivocada.

**Comprueba:**
```bash
flutter test test/etapa1_dominio_test.dart -r expanded    # 6 pruebas
git commit -m "feat(dominio): receta, dificultad y fallas de red"
```

---

## Etapa 2 — JSON → Dart (40 min)

**Archivo:** `lib/datos/recetas_json.dart`.

1. `dificultadDesdeTexto`: `Easy` → `facil`, `Medium` → `media`, `Hard` → `dificil`. Cualquier otra cosa (texto desconocido, `null`, un número) → `desconocida`. **Nunca lanza error.**
2. `recetaDesdeJson`:
   - **Obligatorios** (si faltan o traen otro tipo → `FormatException`): `id` (`int`), `name`, `cuisine` (`String`), `prepTimeMinutes`, `cookTimeMinutes`, `servings` (`int`) y `rating` (número, entero o decimal).
   - `rating` se guarda como `double` aunque llegue como entero.
   - `difficulty` se traduce con `dificultadDesdeTexto`.
   - `tags` e `ingredients` son opcionales: si faltan → lista vacía. Si vienen pero no son una lista, o algún elemento no es texto → `FormatException`.
   - Los demás campos del JSON se ignoran.
3. `paginaDesdeJson`: lee `recipes` (lista) y `total` (`int`); cada elemento de `recipes` debe ser un objeto y se convierte con `recetaDesdeJson`. Si falta alguna llave o un elemento no es un objeto → `FormatException`. Una lista vacía es válida.

**Pistas:**
- Un `switch` con patrón de mapa resuelve los obligatorios en un solo bloque (CONCEPTOS §4).
- `int` y `double` son `num`. El patrón `'rating': num calificacion` acepta los dos.
- Una función privada para "lista de textos opcional" te sirve para `tags` e `ingredients`.
- No uses `as List<String>`: recorre la lista.

**Pregunta para tu reflexión (la responderás en la etapa 6):** si DummyJSON cambiara `rating` por `score`, ¿qué archivos tendrías que modificar?

**Comprueba:**
```bash
flutter test test/etapa2_json_test.dart -r expanded       # 11 pruebas
git commit -m "feat(datos): conversión de JSON a recetas"
```

---

## Etapa 3 — Cliente, bitácora, errores y repositorio (50 min)

**Archivos:** los otros cinco de `lib/datos/`.

1. `crearDioRecetas`: `baseUrl = urlDummyJson`; `connectTimeout` y `receiveTimeout` entre 1 y 30 segundos. Agrega primero un `BitacoraInterceptor` y después los `interceptores` que reciba.
2. `BitacoraInterceptor`: una línea en `onRequest`, `onResponse` y `onError`, con los formatos de la tabla. Si no le pasan `escribir`, usa `developer.log` de `dart:developer`. Siempre llama a `handler.next(...)`. Solo puede usar método, ruta (`path`), código, tipo de error y tiempo.
3. `traducirError`:
   - cualquier timeout → `TiempoAgotado`;
   - `badResponse` con código ≥ 500 → `ErrorDelServidor(codigo)`; con otro código → `PeticionRechazada(codigo)`;
   - `unknown` cuya causa (`e.error`) es una `FormatException` → `RespuestaInvalida`;
   - todo lo demás → `SinConexion`.
4. `RecetasRepositorio`: el contrato abstracto.
5. `DummyJsonRepositorio.buscar`:
   - quita los espacios del texto;
   - texto vacío → `GET /recipes` con query `{limit: 10}` (sin `q`);
   - con texto → `GET /recipes/search` con query `{q: <texto limpio>, limit: 10}`;
   - la respuesta debe ser un objeto; conviértela con `paginaDesdeJson`;
   - un `DioException` sale como `traducirError(e)`; una `FormatException` sale como `RespuestaInvalida`; una respuesta que no es objeto también es `RespuestaInvalida`.

**Pistas:**
- La query **siempre** con `queryParameters`, nunca concatenando texto en la URL.
- Lo que la persona busca viaja en la query: por eso la bitácora usa `options.path` y no `options.uri`. Una prueba busca `enchiladas` y revisa que no aparezca en la bitácora.
- El tiempo de la petición: guarda un `Stopwatch` en `options.extra` (CONCEPTOS §7).
- `switch` sobre `e.type` con todos los valores del enum: si falta uno, no compila.

**Pregunta para tu reflexión:** el 503 de un servidor y el modo avión terminan los dos en "error". ¿En qué se diferencian para HTTP?

**Comprueba:**
```bash
flutter test test/etapa3_datos_test.dart -r expanded      # 19 pruebas
bash verificar_recetario.sh                               # puntos 2 a 5
git commit -m "feat(datos): cliente Dio, bitácora y repositorio DummyJSON"
```

---

## Etapa 4 — Mensajes y ViewModel (35 min)

**Archivos:** `lib/presentacion/mensajes.dart` y `lib/presentacion/recetas_view_model.dart`. Lee: CONCEPTOS §9 y §10.

1. `mensajePara`: los textos exactos de la tabla, con `switch` sobre `FallaRed`.
2. El ViewModel extiende `ChangeNotifier` (de `foundation.dart`, **no** `material.dart`) y recibe el contrato `RecetasRepositorio`.
3. `buscar(texto)`:
   a. si ya está cargando, no hace nada;
   b. guarda el texto **sin espacios** como `ultimaBusqueda`;
   c. pasa a `RecetasCargando` y avisa;
   d. pide la página al repositorio con ese texto;
   e. sin recetas → `RecetasVacias(ultimaBusqueda)`; con recetas → `RecetasListas(recetas, total)`;
   f. una `FallaRed` → `RecetasFallidas(mensajePara(falla))`;
   g. **cualquier otro error** → `RecetasFallidas(mensajeInesperado)`;
   h. avisa.
4. `reintentar()` vuelve a buscar `ultimaBusqueda`.
5. `cargando` y `rapidas` son **getters calculados** a partir del estado.

**Pistas:**
- La prueba cuenta los avisos: **exactamente dos** por búsqueda.
- `rapidas` sale de un `switch` sobre el estado.
- Si la pantalla se cierra mientras la petición viaja, no avises después de `dispose()`.

**Comprueba:**
```bash
flutter test test/etapa4_viewmodel_test.dart -r expanded  # 11 pruebas
bash verificar_recetario.sh                               # punto 6
git commit -m "feat(presentacion): mensajes y RecetasViewModel"
```

---

## Etapa 5 — Tarjeta, pantalla y raíz (40 min)

**Archivos:** `tarjeta_receta.dart`, `recetas_pagina.dart`, `app.dart` y `main.dart`.

1. `TarjetaReceta`: una `Card` con el nombre, el subtítulo, la línea de tiempo y porciones, la calificación con un decimal y, solo si es rápida, un `Chip` con `Rápida`.
2. `RecetasPagina`: `StatefulWidget` (porque tiene un `TextEditingController`). Contiene:
   - `AppBar` con el título;
   - el `TextField` con su llave; al presionar Enter o la tecla de búsqueda del teclado, también busca;
   - el `FilledButton` con su llave, desactivado mientras carga;
   - debajo, el contenido según el estado, escuchando al ViewModel con `ListenableBuilder`;
   - en error, `Reintentar` llama a `vm.reintentar`;
   - con datos, el encabezado y un `ListView` de `TarjetaReceta`.
3. `AppRecetario`: `StatefulWidget` cuyo `State` crea **una vez** el ViewModel con el repositorio recibido, lo libera en `dispose()` y arma un `MaterialApp` con `RecetasPagina`.
4. `main.dart`: `runApp(AppRecetario(repositorio: DummyJsonRepositorio(crearDioRecetas())))`.

**Pistas:**
- `toStringAsFixed(1)` da un decimal.
- `TextField(textInputAction: TextInputAction.search, onSubmitted: ...)` busca con el teclado.
- El `ListView` va dentro de un `Expanded`.
- **No busques en `build` ni en `initState`**: una prueba revisa que al abrir no se pida nada.
- Libera el `TextEditingController` en `dispose()`.

**Comprueba:**
```bash
flutter test test/etapa5_vistas_test.dart -r expanded     # 8 pruebas
flutter test                                              # 55 pruebas
bash verificar_recetario.sh                               # todo OK salvo la etapa 6
flutter run
git commit -m "feat(presentacion): tarjeta, pantalla y raíz de la app"
```

---

## Etapa 6 — Escenarios reales y evidencias (30 min)

Ahora vas a provocar **con el servicio real** los cinco escenarios y documentarlos. Para cada uno toma una captura de pantalla y guárdala en `docs/capturas/` (mínimo 5 imágenes, `.png` o `.jpg`). Copia también la línea de la bitácora que apareció.

| # | Escenario | Cómo provocarlo |
|---|---|---|
| 1 | **Éxito** | Busca `chicken` (o cualquier receta que exista). |
| 2 | **Vacío** | Busca `zzzz`. |
| 3 | **Error del servidor** | Cambio temporal A (abajo): DummyJSON responde 503 de verdad. |
| 4 | **Sin red** | Activa modo avión o apaga el Wi-Fi y busca. Si pruebas en web y no puedes desconectarte, usa el cambio temporal C. |
| 5 | **Tiempo agotado** | Cambio temporal B: le pides a DummyJSON que tarde 5 s y bajas tus timeouts a 2 s. |

### Cambios temporales (se quitan al terminar)

En `lib/main.dart`, pasa **uno** de estos interceptores a `crearDioRecetas(...)`. Necesitarás `import 'package:dio/dio.dart';` mientras lo uses.

```dart
// A) Error del servidor: DummyJSON tiene rutas que responden el código que pidas.
crearDioRecetas(interceptores: [
  InterceptorsWrapper(onRequest: (o, h) { o.path = '/http/503'; h.next(o); }),
])

// B) Tiempo agotado: DummyJSON espera `delay` milisegundos antes de responder.
crearDioRecetas(interceptores: [
  InterceptorsWrapper(onRequest: (o, h) {
    o.queryParameters = {...o.queryParameters, 'delay': 5000};
    o.connectTimeout = const Duration(seconds: 2);
    o.receiveTimeout = const Duration(seconds: 2);
    h.next(o);
  }),
])

// C) Sin red (solo si no puedes desconectarte): un dominio que no existe.
crearDioRecetas(interceptores: [
  InterceptorsWrapper(onRequest: (o, h) { o.baseUrl = 'https://recetario.invalid'; h.next(o); }),
])
```

Al terminar, **regresa `main.dart` a la versión de la etapa 5**. El script falla si quedan `delay`, `/http/...` o `.invalid` en `lib/`.

### `docs/evidencias.md`

Usa esta plantilla. Cada celda se llena con lo que **tú** observaste.

```markdown
# Evidencias — Recetario UTEZ

**Nombre:**
**Matrícula:**
**Fecha:**
**Dispositivo donde se probó:** (emulador Android, teléfono, Chrome, Windows, macOS…)

## 1. Del JSON a Dart

| JSON | Campo Dart | Tipo | Regla (obligatorio, tolerado, valor por defecto) |
|---|---|---|---|
| (una fila por cada campo que usa tu app) | | | |

## 2. Escenarios probados con el servicio real

| Escenario | Cómo lo provoqué | Qué vio la persona | Línea de la bitácora | Captura | Prueba del kit que lo cubre |
|---|---|---|---|---|---|
| Éxito | | | | | |
| Vacío | | | | | |
| Error del servidor | | | | | |
| Sin red | | | | | |
| Tiempo agotado | | | | | |

## 3. Preguntas de reflexión

1. ¿En qué se diferencian el escenario "Error del servidor" y "Sin red" desde el punto de vista de HTTP?
2. ¿Por qué "Vacío" no es un error?
3. La búsqueda de la persona viaja en la query. ¿Por qué tu bitácora no la escribe?
4. Si DummyJSON cambiara `rating` por `score`, ¿qué archivos tendrías que modificar y por qué solo esos?
```

**Comprueba:**
```bash
bash verificar_recetario.sh  # todo en OK
flutter test                 # 55 pruebas
git commit -m "docs: evidencias de los escenarios reales"
```

---

## Si algo falla

| Síntoma | Causa probable |
|---|---|
| `Target of URI doesn't exist: package:recetario_utez/...` | El proyecto no se llama `recetario_utez` o falta un archivo del contrato. |
| `type 'int' is not a subtype of type 'double'` | Usaste `as double` con `rating`. Usa `num` y `.toDouble()`. |
| `type 'List<dynamic>' is not a subtype of type 'List<String>'` | `as List<String>` en `tags`. Recorre la lista. |
| Una prueba de etapa 3 se queda esperando y cae por tiempo | El interceptor no llama `handler.next`. |
| `"escribe método, ruta y código, pero no lo que se buscó"` falla | Usas `options.uri` o `queryParameters` en la bitácora. |
| `"al abrir no busca"` falla | Llamas `buscar` en `build` o en `initState`. |
| `"dos avisos"` falla | Llamas `notifyListeners()` de más o de menos. |
| La prueba no encuentra `Calificación: 4.4` | Usa `toStringAsFixed(1)`. |
| `verificar` dice que la vista importa `lib/datos` | La vista recibe el ViewModel, no el repositorio. |
| Android release sin datos | Falta el permiso `INTERNET` en el manifiesto principal. |
| Web: `XMLHttpRequest error` | Revisa la URL; DummyJSON permite CORS. |
| En web, el timeout aparece como `connectionTimeout` | Es normal en el navegador; los dos se traducen a `TiempoAgotado`. |

Más casos en CONCEPTOS §12.

---

## Definición de terminado

- [x] `flutter test` pasa completo: 55 pruebas.
- [x] `bash verificar_recetario.sh` sale todo en OK.
- [x] `flutter run` busca recetas reales y muestra tarjetas.
- [x] `docs/evidencias.md` tiene los cinco escenarios, la tabla del JSON y las cuatro respuestas.
- [x] `docs/capturas/` tiene al menos 5 imágenes.
- [x] `main.dart` no tiene cambios temporales.
- [x] Hay un commit por etapa.

---

## Cómo se evalúa (100 puntos)

| Concepto | Puntos |
|---|---|
| Etapa 1 — `etapa1_dominio_test.dart` (6 pruebas) | 8 |
| Etapa 2 — `etapa2_json_test.dart` (11 pruebas) | 17 |
| Etapa 3 — `etapa3_datos_test.dart` (19 pruebas) | 20 |
| Etapa 4 — `etapa4_viewmodel_test.dart` (11 pruebas) | 15 |
| Etapa 5 — `etapa5_vistas_test.dart` (8 pruebas) | 15 |
| `verificar_recetario.sh` todo en OK | 10 |
| `docs/evidencias.md` y capturas | 10 |
| Historial de Git (un commit por etapa) | 5 |
| **Total** | **100** |

- Cada etapa vale sus puntos multiplicados por la fracción de pruebas que pasan **con el kit limpio**. Ejemplo: 15 de 19 en la etapa 3 → 20 × 15/19 = 15.8 puntos.
- Si el proyecto no compila, las pruebas no corren: las etapas valen 0.
- Si una prueba o el script fueron modificados, esa etapa vale 0.
- El script cuenta completo o nada: 10 si sale todo OK, 5 si falta un solo punto, 0 si faltan más.
- Evidencias: 2 puntos por escenario con captura, bitácora y descripción coherentes (máximo 10); se restan 2 si faltan las respuestas de reflexión.

---

## Retos extra (no suman puntos)

1. **Imagen:** muestra `image` en la tarjeta con `Image.network` y un `errorBuilder` para cuando no cargue. ¿Por qué hace falta el `errorBuilder`?
2. **Cargar más:** usa `skip` para traer la siguiente página y agrégala a la lista. ¿Qué haces si la segunda página falla y ya hay datos en pantalla?
3. **Menos datos:** DummyJSON acepta `select=name,cuisine,...` para mandar solo los campos que usas. Agrégalo y compara el tamaño de la respuesta en DevTools → Network.
4. **Detalle:** al tocar una tarjeta, abre una pantalla con los ingredientes. ¿Necesitas otra petición o ya tienes los datos?
