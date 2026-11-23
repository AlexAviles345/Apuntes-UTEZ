# Geolocalización Consciente y Reutilizable (`geo-helper.js`) — Explicación del Código

Esta guía explica la arquitectura y cada archivo del proyecto [`pwa-geo-modular/`](pwa-geo-modular/), que implementa un módulo promisificado y reutilizable de geolocalización ([`geo-helper.js`](pwa-geo-modular/geo-helper.js)), aplica el patrón de **consentimiento previo (Pre-Permiso UX)** inspeccionando la **Permissions API**, ofrece un **Plan B (degradación elegante)** con selector manual de zona ante bloqueos o errores de tiempo de espera (`TIMEOUT`), y diagnostica la calidad de la señal (`coords.accuracy`) en JavaScript Vanilla puro (`.then()` y `.catch()`).

Para preparar las preguntas técnicas y la comparación presencial entre laptop y teléfono móvil, consulta [Geolocalización Consciente y Reutilizable — Respuestas para la defensa oral](Geolocalizaci%C3%B3n%20Consciente%20y%20Reutilizable%20-%20Respuestas%20para%20la%20defensa%20oral.md).

---

## Archivos de la Práctica

| Archivo | Responsabilidad |
|---|---|
| [`index.html`](pwa-geo-modular/index.html) | Define la estructura visual: tarjeta del reporte técnico (`#btn-adjuntar`), tarjeta de pre-permiso (`#card-prepermiso`), aviso de bloqueo (`#card-denegado`), selector manual Plan B (`#card-manual`), tarjeta de resultados (`#card-resultado`) y carga [`geo-helper.js`](pwa-geo-modular/geo-helper.js) antes que [`app.js`](pwa-geo-modular/app.js) |
| [`styles.css`](pwa-geo-modular/styles.css) | Estiliza las tarjetas, botones, estados de carga/error, la regla `[hidden]` y las etiquetas visuales (`.badge.alta` en verde y `.badge.aprox` en ámbar) |
| [`geo-helper.js`](pwa-geo-modular/geo-helper.js) | Módulo independiente y reutilizable que encapsula `navigator.geolocation.getCurrentPosition()` en `new Promise()`, traduce los códigos `1`, `2` y `3` a mensajes legibles y consulta `navigator.permissions.query({ name: 'geolocation' })` |
| [`app.js`](pwa-geo-modular/app.js) | Controla la interfaz de usuario, ejecuta el flujo de 3 estados del permiso (`granted`, `prompt`, `denied`), evalúa el umbral de 30 metros para clasificar la precisión, activa el Plan B manual y registra el Service Worker |
| [`sw.js`](pwa-geo-modular/sw.js) | Precarga el App Shell completo (incluyendo `./geo-helper.js`) con rutas relativas `./`, limpia cachés antiguas en `activate` y responde con estrategia *Cache First* en `fetch` |
| [`manifest.json`](pwa-geo-modular/manifest.json) | Configura los metadatos de instalabilidad (`standalone`, colores e iconos `192x192` y `512x512` con rutas `./`) |
| [`icons/icon-192.png`](pwa-geo-modular/icons/icon-192.png) | Icono PNG físico de `192x192` píxeles |
| [`icons/icon-512.png`](pwa-geo-modular/icons/icon-512.png) | Icono PNG físico de `512x512` píxeles |

---

## 1. Arquitectura Modular y Orden de Carga

A diferencia de las APIs modernas basadas en promesas (como `fetch` o `getUserMedia`), `navigator.geolocation` pertenece a una generación anterior del estándar web y funciona mediante **callbacks tradicionales** (`successCallback` y `errorCallback`).

Para evitar duplicar callbacks anidados cada vez que una pantalla necesite coordenadas, la práctica separa la arquitectura en dos capas:

```text
┌──────────────────────────────────────────────────────────────┐
│                        index.html                            │
│  1. <script src="./geo-helper.js"></script> (Capa de Datos)  │
│  2. <script src="./app.js"></script>        (Capa de UI)     │
└───────────────┬──────────────────────────────┬───────────────┘
                │                              │
                ▼                              ▼
┌───────────────────────────────┐  ┌───────────────────────────┐
│         geo-helper.js         │  │          app.js           │
│ - traducirErrorGeolocalizacion│◄─┤ - manejarClickAdjuntar()  │
│ - obtenerUbicacionActual()    │  │ - solicitarUbicacion()    │
│ - consultarEstadoPermisoGeo() │  │ - renderizarResultado...()│
└───────────────────────────────┘  │ - habilitarSelector...()  │
                                   └───────────────────────────┘
```

> **Por qué importa el orden en [`index.html` (L96–L97)](pwa-geo-modular/index.html#L96-L97):** Al no usar empaquetadores externos, ambos scripts comparten el ámbito global (`window`). Cargar `./geo-helper.js` primero garantiza que `obtenerUbicacionActual` y `consultarEstadoPermisoGeo` ya estén definidas en memoria cuando `app.js` se inicializa.

---

## 2. `geo-helper.js`: Promisificación, Normalización y Permisos

El archivo [`geo-helper.js`](pwa-geo-modular/geo-helper.js) expone tres funciones puras en JavaScript Vanilla sin tocar ningún elemento del DOM.

### 2.1 Traducción de códigos de error (`traducirErrorGeolocalizacion`)

Cuando `navigator.geolocation.getCurrentPosition` falla, entrega un objeto `GeolocationPositionError` con una propiedad numérica `error.code`:

```javascript
function traducirErrorGeolocalizacion(error) {
  switch (error.code) {
    case 1: // PERMISSION_DENIED
      return 'Permiso de ubicación denegado. Puedes ingresar tu zona manualmente.';
    case 2: // POSITION_UNAVAILABLE
      return 'No fue posible determinar tu ubicación (señal GPS o Wi-Fi no disponible).';
    case 3: // TIMEOUT
      return 'Se agotó el tiempo de espera intentando obtener las coordenadas.';
    default:
      return 'Ocurrió un error inesperado al consultar la ubicación.';
  }
}
```

| Código (`error.code`) | Constante estándar | Causa técnica real |
|---|---|---|
| `1` | `PERMISSION_DENIED` | El usuario pulsó *"Bloquear"* en el diálogo del navegador o el servicio de ubicación está desactivado a nivel de sistema operativo |
| `2` | `POSITION_UNAVAILABLE` | El hardware GPS/GNSS no logra fijar satélites y la red Wi-Fi/IP tampoco pudo triangular la posición |
| `3` | `TIMEOUT` | Se superó el límite de milisegundos configurado en `options.timeout` sin obtener una coordenada (muy común en laptops sin GPS cuando se pide `enableHighAccuracy: true`) |

---

### 2.2 Promisificación de `getCurrentPosition` (`obtenerUbicacionActual`)

```javascript
function obtenerUbicacionActual(opcionesPersonalizadas) {
  const opciones = Object.assign(
    {
      enableHighAccuracy: true,
      timeout: 8000,
      maximumAge: 30000
    },
    opcionesPersonalizadas
  );

  return new Promise((resolve, reject) => {
    if (!('geolocation' in navigator)) {
      reject(new Error('Este navegador no soporta la API de Geolocalización.'));
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (posicion) => {
        resolve({
          latitud: posicion.coords.latitude,
          longitud: posicion.coords.longitude,
          precisionMetros: Math.round(posicion.coords.accuracy),
          timestamp: posicion.timestamp
        });
      },
      (error) => {
        const err = new Error(traducirErrorGeolocalizacion(error));
        err.code = error.code; // conservamos el código original para decidir el Plan B
        reject(err);
      },
      opciones
    );
  });
}
```

#### Detalles técnicos clave

1. **Fusión de opciones con `Object.assign`:**
   Define valores por defecto seguros (`enableHighAccuracy: true`, `timeout: 8000` ms, `maximumAge: 30000` ms) pero permite que cualquier función consumidora los sobrescriba pasando un objeto (por ejemplo, `{ enableHighAccuracy: false, maximumAge: 60000 }` para una búsqueda rápida sin gastar batería).
2. **Encapsulamiento en `new Promise((resolve, reject) => ...)`:**
   Convierte la API antigua basada en callbacks en una Promesa estándar que se consume con `.then()` y `.catch()`.
3. **Normalización del objeto de salida:**
   En lugar de exponer la estructura anidada `posicion.coords.latitude`, devuelve un objeto plano y limpio (`{ latitud, longitud, precisionMetros, timestamp }`) con el margen de error ya redondeado a metros enteros (`Math.round(posicion.coords.accuracy)`).
4. **Preservación de `err.code`:**
   Al construir `const err = new Error(...)` y asignarle `err.code = error.code`, el bloque `.catch()` en `app.js` recibe tanto el mensaje en español listo para mostrar como el código numérico (`1`, `2` o `3`) para saber si debe desplegar la tarjeta de instrucciones de desbloqueo (`#card-denegado`).

---

### 2.3 Inspección previa de la Permissions API (`consultarEstadoPermisoGeo`)

```javascript
function consultarEstadoPermisoGeo() {
  if (!('permissions' in navigator)) {
    return Promise.resolve('prompt');
  }

  return navigator.permissions.query({ name: 'geolocation' })
    .then((resultado) => resultado.state) // 'granted' | 'denied' | 'prompt'
    .catch(() => 'prompt');
}
```

- Consulta de forma silenciosa (sin abrir ningún cuadro de diálogo) en qué estado se encuentra el permiso de ubicación para el dominio actual:
  - `'granted'`: el usuario ya dio permiso anteriormente.
  - `'denied'`: el usuario bloqueó el permiso.
  - `'prompt'`: el usuario aún no ha tomado una decisión (o seleccionó *"Permitir una vez"* en una sesión previa).
- **Degradación elegante en la consulta:** Si el navegador no soporta `navigator.permissions` o lanza una excepción al consultar `'geolocation'`, la función resuelve con `'prompt'` por defecto (`Promise.resolve('prompt')` / `.catch(() => 'prompt')`), asegurando que siempre se muestre la tarjeta de pre-permiso antes de tocar el hardware.

---

## 3. `index.html`: Las 5 Tarjetas del Flujo de Experiencia de Usuario

El documento [`index.html`](pwa-geo-modular/index.html) organiza la interfaz en cinco secciones (`<section class="card">`), cuatro de las cuales inician ocultas con el atributo nativo `hidden`:

1. **Acción principal ([L20–L27](pwa-geo-modular/index.html#L20-L27)):**
   Contiene el botón `#btn-adjuntar` (*"Adjuntar mi ubicación"*) y el párrafo de estado `#estado` con `role="status"` y `aria-live="polite"`.
2. **Tarjeta de Pre-Permiso `#card-prepermiso` ([L30–L45](pwa-geo-modular/index.html#L30-L45)):**
   Explica al usuario por qué se solicita su ubicación (*"adjuntar las coordenadas al reporte técnico y calcular la sucursal más cercana"*) y ofrece dos botones:
   - `#btn-confirmar` (*"Compartir mi ubicación"*): dispara la llamada real a `navigator.geolocation.getCurrentPosition()` directamente desde el gesto `click` del usuario (requisito estricto de Safari en iOS).
   - `#btn-cancelar` (*"Ahora no"*): cierra el aviso y pasa directamente al selector manual de zona sin tocar el permiso nativo del navegador.
3. **Tarjeta de Permiso Bloqueado `#card-denegado` ([L48–L57](pwa-geo-modular/index.html#L48-L57)):**
   Explica paso a paso cómo reactivar el permiso en la barra de direcciones (Chrome/Android/Desktop) o en `Ajustes → Privacidad → Localización → Safari` (iPhone).
4. **Tarjeta Plan B `#card-manual` ([L60–L79](pwa-geo-modular/index.html#L60-L79)):**
   Selector `<select id="select-zona">` con municipios de Morelos (`Cuernavaca`, `Emiliano Zapata`, `Jiutepec`, `Temixco`, `Xochitepec`, `Cuautla`, `Yautepec`) y campo de dirección opcional `#input-direccion` para que el usuario nunca quede bloqueado si falla el GPS o rechaza el permiso.
5. **Tarjeta de Resultado `#card-resultado` ([L82–L92](pwa-geo-modular/index.html#L82-L92)):**
   Muestra la etiqueta de calidad de señal (`#badge-precision`), latitud (`#res-lat`), longitud (`#res-lon`), margen de error en metros (`#res-prec`), fecha/hora de lectura (`#res-fecha`) y un enlace directo para abrir la coordenada en OpenStreetMap (`#enlace-mapa`).

---

## 4. `app.js`: Flujo de Pre-Permiso, Diagnóstico de Precisión y Plan B

### 4.1 Árbol de decisión al pulsar "Adjuntar mi ubicación" (`manejarClickAdjuntar`)

En [`app.js` (L99–L117)](pwa-geo-modular/app.js#L99-L117):

```javascript
function manejarClickAdjuntar() {
  ocultarTodo();
  mostrarEstado('Consultando estado del permiso...');

  consultarEstadoPermisoGeo().then((estado) => {
    mostrarEstado('');

    if (estado === 'granted') {
      solicitarUbicacion();
    } else if (estado === 'denied') {
      cardDenegado.hidden = false;
      habilitarSelectorManualZona();
    } else {
      // 'prompt' -> tarjeta explicativa; el diálogo nativo solo se dispara
      // cuando el usuario pulsa "Compartir mi ubicación" (clic directo, requisito iOS)
      cardPrePermiso.hidden = false;
    }
  });
}
```

- **Caso 1 (`estado === 'granted'`):** Como el usuario ya había otorgado permiso previamente, no lo hacemos pasar de nuevo por la tarjeta explicativa; se invoca `solicitarUbicacion()` directamente.
- **Caso 2 (`estado === 'prompt'`):** Se muestra `#card-prepermiso`. El navegador todavía **no** abre su ventana nativa. Solo cuando el usuario lee la explicación y pulsa `#btn-confirmar` (*"Compartir mi ubicación"*), `manejarConfirmar()` llama a `solicitarUbicacion()`.
- **Caso 3 (`estado === 'denied'`):** Sabemos de antemano que el navegador tiene bloqueada la ubicación. En vez de fallar en silencio, mostramos `#card-denegado` con las instrucciones de desbloqueo y habilitamos inmediatamente `#card-manual` (Plan B).

---

### 4.2 Solicitud de coordenadas y activación automática del Plan B (`solicitarUbicacion`)

En [`app.js` (L76–L95)](pwa-geo-modular/app.js#L76-L95):

```javascript
function solicitarUbicacion() {
  mostrarCargando('Obteniendo coordenadas...');

  return obtenerUbicacionActual({ enableHighAccuracy: true, timeout: 8000 })
    .then((ubicacion) => {
      ocultarTodo();
      console.log('[Geo] Ubicación obtenida:', ubicacion);
      renderizarResultadoUbicacion(ubicacion);
    })
    .catch((error) => {
      console.warn('[Geo] Fallback activado:', error.message);
      cardPrePermiso.hidden = true;
      mostrarMensajeError(error.message);
      if (error.code === 1) {
        cardDenegado.hidden = false;
      }
      habilitarSelectorManualZona(); // Plan B: nunca bloquear al usuario
    })
    .then(quitarCargando);
}
```

- Mientras el hardware busca satélites o triangula redes Wi-Fi, `mostrarCargando()` deshabilita los botones (`disabled = true`) para evitar clics duplicados.
- Si ocurre cualquier error en `.catch()` (`PERMISSION_DENIED`, `POSITION_UNAVAILABLE` o `TIMEOUT`), se oculta la tarjeta de pre-permiso, se pinta el mensaje traducido en rojo, se muestra `#card-denegado` si fue código `1`, y **siempre** se llama a `habilitarSelectorManualZona()`.
- El `.then(quitarCargando)` final (encadenado después del `.catch()`) actúa como cierre seguro para reactivar los botones tanto en éxito como en error.

---

### 4.3 Diagnóstico de Calidad de Señal (`renderizarResultadoUbicacion`)

En [`app.js` (L3 y L52–L72)](pwa-geo-modular/app.js#L52-L72):

```javascript
const UMBRAL_PRECISION_ALTA = 30; // metros

function renderizarResultadoUbicacion(ubicacion) {
  const esAlta = ubicacion.precisionMetros < UMBRAL_PRECISION_ALTA;
  const badge = $('badge-precision');

  badge.textContent = esAlta
    ? 'Precisión GPS Alta'
    : 'Ubicación Aproximada (Wi-Fi / IP)';
  badge.className = 'badge ' + (esAlta ? 'alta' : 'aprox');
  ...
```

| Condición (`ubicacion.precisionMetros`) | Etiqueta en `#badge-precision` | Clase CSS | Significado físico |
|---|---|---|---|
| `< 30` metros | **`Precisión GPS Alta`** | `.badge.alta` (verde) | Coordenada fijada por chip satelital GPS/GNSS (típico en un teléfono móvil Android o iPhone al aire libre o cerca de ventanas) |
| `>= 30` metros | **`Ubicación Aproximada (Wi-Fi / IP)`** | `.badge.aprox` (ámbar) | Coordenada estimada por triangulación de módems Wi-Fi cercanos o ubicación del proveedor de Internet / IP (típico en una laptop o PC de escritorio sin chip GPS) |

---

## 5. `sw.js`: Precaché del Módulo `geo-helper.js`

En [`sw.js` (L2–L13)](pwa-geo-modular/sw.js#L2-L13):

```javascript
const CACHE_NAME = 'geo-pwa-modular-v1';

const APP_SHELL = [
  './',
  './index.html',
  './styles.css',
  './geo-helper.js',
  './app.js',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png'
];
```

Incluir `'./geo-helper.js'` en el arreglo `APP_SHELL` es obligatorio para la arquitectura modular: si el Service Worker solo cacheara `index.html` y `app.js` pero olvidara `geo-helper.js`, al abrir la PWA sin conexión `app.js` fallaría con `ReferenceError: obtenerUbicacionActual is not defined`, impidiendo incluso que funcione el selector manual del Plan B.

---

## 6. Diagrama de Flujo Completo

```text
Usuario pulsa "Adjuntar mi ubicación" (#btn-adjuntar)
  └── consultarEstadoPermisoGeo() (navigator.permissions.query)
        ├── 'granted' ────────────────────────────────────────┐
        ├── 'denied'  ──► Muestra #card-denegado + #card-manual (Plan B)
        └── 'prompt'  ──► Muestra #card-prepermiso
                            ├── Usuario pulsa "Ahora no" (#btn-cancelar)
                            │     └── Muestra #card-manual (Plan B)
                            └── Usuario pulsa "Compartir mi ubicación" (#btn-confirmar)
                                  │
                                  ▼
                        solicitarUbicacion() ◄────────────────┘
                          └── obtenerUbicacionActual({ enableHighAccuracy: true, timeout: 8000 })
                                ├── Éxito (.then)
                                │     └── renderizarResultadoUbicacion(ubicacion)
                                │           ├── precisionMetros < 30  ──► "Precisión GPS Alta"
                                │           └── precisionMetros >= 30 ──► "Ubicación Aproximada (Wi-Fi / IP)"
                                └── Error (.catch)
                                      ├── Traduce código 1, 2 o 3 a español
                                      ├── Si error.code === 1 ──► Muestra #card-denegado
                                      └── Muestra #card-manual (Plan B: selección manual de municipio)
```
