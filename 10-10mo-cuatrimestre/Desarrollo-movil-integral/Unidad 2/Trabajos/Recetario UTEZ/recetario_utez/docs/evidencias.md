# Evidencias — Recetario UTEZ

**Nombre:** Alexandro Jesús Cerón Avilés
**Matrícula:** 20233tn198
**Fecha:** 11/11/2026
**Dispositivo donde se probó:** Chrome / Windows

## 1. Del JSON a Dart

| JSON | Campo Dart | Tipo | Regla (obligatorio, tolerado, valor por defecto) |
|---|---|---|---|
| `id` | `Receta.id` | `int` | Obligatorio; si falta o no es entero → `FormatException` |
| `name` | `Receta.nombre` | `String` | Obligatorio |
| `cuisine` | `Receta.cocina` | `String` | Obligatorio |
| `difficulty` | `Receta.dificultad` | `Dificultad` | Tolerado: `Easy`/`Medium`/`Hard` se traducen; cualquier otra cosa, `null` o ausente → `Dificultad.desconocida` |
| `prepTimeMinutes` | `Receta.minutosPreparacion` | `int` | Obligatorio |
| `cookTimeMinutes` | `Receta.minutosCoccion` | `int` | Obligatorio |
| `servings` | `Receta.porciones` | `int` | Obligatorio |
| `rating` | `Receta.calificacion` | `double` | Obligatorio; llega como `num` (entero o decimal) y se guarda con `.toDouble()` |
| `tags` | `Receta.etiquetas` | `List<String>` | Opcional → lista vacía; si no es lista de textos → `FormatException` |
| `ingredients` | `Receta.ingredientes` | `List<String>` | Opcional → lista vacía; si no es lista de textos → `FormatException` |
| `recipes` | `PaginaRecetas.recetas` | `List<Receta>` | Obligatorio (puede ser lista vacía); cada elemento debe ser un objeto |
| `total` | `PaginaRecetas.total` | `int` | Obligatorio |

Los demás campos del JSON (`instructions`, `image`, `userId`, etc.) se ignoran.

## 2. Escenarios probados con el servicio real

| Escenario | Cómo lo provoqué | Qué vio la persona | Línea de la bitácora | Captura | Prueba del kit que lo cubre |
|---|---|---|---|---|---|
| Éxito | Busqué `chicken` | Encabezado "Mostrando 6 de 6 recetas · Rápidas: 2" y tarjetas | `← 200 GET /recipes/search (215 ms)` | `capturas/soleado.png` | etapa3: "200 → PaginaRecetas"; etapa5: "texto + botón → … → tarjetas" |
| Vacío | Busqué `zzzz` | `No encontramos recetas para "zzzz".` (no es un error) | `← 200 GET /recipes/search (142 ms)` | `capturas/nublado.png` | etapa3: "200 sin resultados → página vacía"; etapa5: "vacío con texto dice qué se buscó…" |
| Error del servidor | Cambio temporal A (`/http/503`) | Mensaje "El recetario no está disponible (503). Intenta más tarde." y botón Reintentar | `✗ badResponse 503 GET /http/503 (180 ms)` | `capturas/lluvioso.png` | etapa3: "503 → ErrorDelServidor(503)"; etapa4: "FallaRed → Fallidas…" |
| Sin red | Modo avión (o cambio temporal C `https://recetario.invalid`) | "Sin conexión. Revisa tu red e intenta de nuevo." y botón Reintentar | `✗ connectionError GET /recipes (12 ms)` | `capturas/tormenta (1).png` | etapa3: "sin red → SinConexion"; etapa5: "error → mensaje y Reintentar…" |
| Tiempo agotado | Cambio temporal B (`delay=5000`, timeouts de 2 s) | "El recetario tardó demasiado en responder. Intenta de nuevo." y botón Reintentar | `✗ receiveTimeout GET /recipes (2004 ms)` | `capturas/lluvioso (1).png` | etapa3: "connectTimeout / receiveTimeout → TiempoAgotado" |

## 3. Preguntas de reflexión

1. **¿En qué se diferencian el escenario "Error del servidor" y "Sin red" desde el punto de vista de HTTP?**
   En el error del servidor sí hubo conversación HTTP: la petición llegó, el servidor contestó y trae un código de estado (`503`). En "sin red" la petición nunca llegó al servidor, así que no hay respuesta ni código, solo una excepción de conexión. Por eso se traducen distinto: `badResponse` con código ≥ 500 → `ErrorDelServidor(503)`, y un error de conexión → `SinConexion`. Además cambia lo que se le dice a la persona (inténtalo más tarde vs. revisa tu red).

2. **¿Por qué "Vacío" no es un error?**
   Porque la petición funcionó: el servidor respondió `200` con `"recipes": []`. No hubo falla de red ni de formato; simplemente no hay coincidencias. Es un resultado válido del dominio, por eso tiene su propio estado (`RecetasVacias`) y un mensaje que dice qué se buscó, y no pasa por `FallaRed`.

3. **La búsqueda de la persona viaja en la query. ¿Por qué tu bitácora no la escribe?**
   Porque lo que escribe la persona puede ser información personal y las bitácoras se copian, se comparten y se suben a reportes de errores. La bitácora solo registra método, ruta (`options.path`, que no incluye la query), código y tiempo. Usar la URL completa (`options.uri`) filtraría el texto buscado.

4. **Si DummyJSON cambiara `rating` por `score`, ¿qué archivos tendrías que modificar y por qué solo esos?**
   Solo `lib/datos/recetas_json.dart`, que es la única frontera entre el JSON y el dominio: ahí cambia la llave `'rating'` por `'score'`. El dominio (`Receta.calificacion`), el ViewModel y las vistas no saben cómo se llama el campo en el JSON, así que no cambian. (También habría que actualizar los datos de prueba en `test/soporte/json_dummy.dart`.)
