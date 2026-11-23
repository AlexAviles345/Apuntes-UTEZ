# Geolocalización Consciente y Reutilizable — Respuestas para la Defensa Oral

Esta guía prepara las respuestas técnicas de 60 segundos y los puntos exactos del código que debes señalar durante la evaluación en vivo (comparando **laptop vs. teléfono móvil**) de la práctica del **Tema 6.3**.

Para revisar primero la explicación detallada de la arquitectura y de cada archivo, consulta [Geolocalización Consciente y Reutilizable — Explicación del código](Geolocalizaci%C3%B3n%20Consciente%20y%20Reutilizable%20-%20Explicaci%C3%B3n%20del%20c%C3%B3digo.md).

---

## Mapa Rápido para Señalar en el Código

| Qué te pide mostrar el profesor | Archivo y líneas |
|---|---|
| Orden de importación de scripts (`geo-helper.js` antes de `app.js`) | [`index.html` (L96–L97)](pwa-geo-modular/index.html#L96-L97) |
| Tarjeta explicativa de Pre-Permiso (`#card-prepermiso`) | [`index.html` (L30–L45)](pwa-geo-modular/index.html#L30-L45) |
| Selector manual de zona / Plan B (`#card-manual`) | [`index.html` (L60–L79)](pwa-geo-modular/index.html#L60-L79) |
| Traducción de códigos nativos `1`, `2` y `3` (`traducirErrorGeolocalizacion`) | [`geo-helper.js` (L3–L14)](pwa-geo-modular/geo-helper.js#L3-L14) |
| Promisificación de `getCurrentPosition` con `new Promise()` (`obtenerUbicacionActual`) | [`geo-helper.js` (L16–L49)](pwa-geo-modular/geo-helper.js#L16-L49) |
| Consulta previa a la Permissions API (`consultarEstadoPermisoGeo`) | [`geo-helper.js` (L51–L59)](pwa-geo-modular/geo-helper.js#L51-L59) |
| Umbral de 30 metros y etiqueta visual de calidad de señal (`renderizarResultadoUbicacion`) | [`app.js` (L3 y L52–L72)](pwa-geo-modular/app.js#L52-L72) |
| Consumo de la promesa y fallback al Plan B en `.catch()` (`solicitarUbicacion`) | [`app.js` (L76–L95)](pwa-geo-modular/app.js#L76-L95) |
| Árbol de decisión según el estado `'granted'`, `'denied'` o `'prompt'` (`manejarClickAdjuntar`) | [`app.js` (L99–L117)](pwa-geo-modular/app.js#L99-L117) |
| Inclusión de `./geo-helper.js` en el App Shell del Service Worker | [`sw.js` (L4–L13)](pwa-geo-modular/sw.js#L4-L13) |

---

## Pregunta 1: Comparación en Vivo — ¿Por qué el `accuracy` varía tanto entre tu Laptop y tu Teléfono Móvil?

> *«Al abrir tu enlace de GitHub Pages en la laptop y en tu teléfono al mismo tiempo, ¿por qué en el celular marca "Precisión GPS Alta" (± 5 a 20 m) y en la laptop marca "Ubicación Aproximada (Wi-Fi / IP)" (cientos o miles de metros), o incluso tarda más?»*

### Qué señalar en el código

En [`app.js` (L3 y L52–L63)](pwa-geo-modular/app.js#L52-L63):

```javascript
const UMBRAL_PRECISION_ALTA = 30; // metros

function renderizarResultadoUbicacion(ubicacion) {
  const esAlta = ubicacion.precisionMetros < UMBRAL_PRECISION_ALTA;
  const badge = $('badge-precision');

  badge.textContent = esAlta
    ? 'Precisión GPS Alta'
    : 'Ubicación Aproximada (Wi-Fi / IP)';
  badge.className = 'badge ' + (esAlta ? 'alta' : 'aprox');
```

### Explicación técnica

- **En el teléfono móvil (Android / iPhone):** El dispositivo cuenta con un **chip satelital GNSS/GPS dedicado**, asistido además por antenas celulares y redes Wi-Fi. Cuando pedimos `enableHighAccuracy: true`, el sistema operativo enciende el receptor GPS y logra un radio de confianza (`coords.accuracy`) de entre **3 y 20 metros**, quedando por debajo del umbral de `30` metros.
- **En la laptop / PC de escritorio:** Casi ninguna laptop tiene chip GPS satelital. Aunque le pasemos `enableHighAccuracy: true`, no puede crear precisión satelital; el sistema operativo solo puede estimar la posición escaneando las **direcciones MAC/BSSID de los módems Wi-Fi cercanos** (error de 30 m a 300 m) o usando la **dirección IP del proveedor de Internet** (error de 1,000 m a 10,000 m).

### Respuesta de 60 segundos

> La diferencia se debe a la fuente física de hardware. `coords.accuracy` mide el radio de margen de error en metros con un 95% de confianza. En mi teléfono móvil existe un chip GPS/GNSS real que, al recibir `enableHighAccuracy: true`, fija coordenadas satelitales con un error menor a 30 metros, activando el badge verde de *"Precisión GPS Alta"*. En cambio, mi laptop no tiene chip GPS; depende de triangular redes Wi-Fi cercanas o la dirección IP del proveedor de Internet, por lo que `coords.accuracy` supera los 30 metros y mi código lo clasifica como *"Ubicación Aproximada (Wi-Fi / IP)"*.

---

## Pregunta 2: ¿Por qué encapsular `navigator.geolocation` dentro de `new Promise()` en `geo-helper.js`?

> *«¿Por qué creaste el archivo `geo-helper.js` con `new Promise()` en lugar de llamar a `navigator.geolocation.getCurrentPosition()` directamente dentro de `app.js`?»*

### Qué señalar en el código

En [`geo-helper.js` (L16–L49)](pwa-geo-modular/geo-helper.js#L16-L49):

```javascript
function obtenerUbicacionActual(opcionesPersonalizadas) {
  const opciones = Object.assign(
    { enableHighAccuracy: true, timeout: 8000, maximumAge: 30000 },
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
        err.code = error.code;
        reject(err);
      },
      opciones
    );
  });
}
```

### Respuesta de 60 segundos

> `navigator.geolocation` es una API antigua que no devuelve promesas, sino que exige dos callbacks (`exito` y `error`). Si la llamáramos directo en la interfaz, tendríamos que repetir callbacks anidados, validaciones de soporte y el `switch` de códigos de error en cada formulario de la PWA. Al encapsularla con `new Promise()` en `geo-helper.js`, normalizamos la respuesta en un objeto limpio (`latitud`, `longitud`, `precisionMetros`, `timestamp`), traducimos los errores `1`, `2` y `3` en un solo lugar, y permitimos que cualquier función en `app.js` solicite coordenadas en una sola línea encadenando `.then()` y `.catch()`.

---

## Pregunta 3: Flujo de Pre-Permiso con `navigator.permissions.query` y Plan B

> *«Explica qué hace exactamente tu aplicación cuando el usuario pulsa "Adjuntar mi ubicación" y cómo actúa `consultarEstadoPermisoGeo()` antes de pedir las coordenadas.»*

### Qué señalar en el código

En [`geo-helper.js` (L51–L59)](pwa-geo-modular/geo-helper.js#L51-L59) y [`app.js` (L99–L117)](pwa-geo-modular/app.js#L99-L117):

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

### Respuesta de 60 segundos

> Al pulsar *"Adjuntar mi ubicación"*, no llamamos todavía a `getCurrentPosition()`. Primero ejecutamos `consultarEstadoPermisoGeo()`, que inspecciona la Permissions API sin disparar ningún diálogo nativo:
> 1. Si devuelve `'granted'`, el usuario ya nos dio permiso antes, así que llamamos directo a `solicitarUbicacion()`.
> 2. Si devuelve `'prompt'`, mostramos nuestra tarjeta explicativa `#card-prepermiso` para que el usuario entienda para qué necesitamos sus coordenadas antes de que vea el diálogo del sistema.
> 3. Si devuelve `'denied'`, mostramos `#card-denegado` explicando cómo desbloquear el candado de la URL y activamos de inmediato el selector manual `#card-manual` como Plan B para no bloquear su reporte.

---

## Pregunta 4: Códigos de Error de `GeolocationPositionError` (`1`, `2`, `3`) y la trampa del `TIMEOUT`

> *«¿Qué significan los códigos de error 1, 2 y 3 en `traducirErrorGeolocalizacion`, y por qué `enableHighAccuracy: true` puede provocar el error código 3 en una laptop?»*

### Qué señalar en el código

En [`geo-helper.js` (L3–L14)](pwa-geo-modular/geo-helper.js#L3-L14) y [`app.js` (L85–L93)](pwa-geo-modular/app.js#L85-L93):

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

### Respuesta de 60 segundos

> La API nativa maneja tres códigos numéricos:
> - **Código `1` (`PERMISSION_DENIED`):** El usuario rechazó el permiso o tiene apagada la ubicación en su sistema operativo.
> - **Código `2` (`POSITION_UNAVAILABLE`):** El dispositivo no pudo triangular la posición ni por GPS ni por red.
> - **Código `3` (`TIMEOUT`):** Se agotaron los 8,000 milisegundos configurados en `timeout` sin obtener respuesta. En una laptop sin chip GPS, poner `enableHighAccuracy: true` obliga al sistema operativo a escanear tarjetas Wi-Fi durante más tiempo; si está conectada por cable o sin mapeo Wi-Fi, agota el tiempo y lanza código `3`. En los tres casos, nuestro `.catch()` captura el error y despliega el selector manual del Plan B.

---

## Pregunta 5: Reglas Críticas en iPhone (iOS / WebKit) y en el Service Worker

> *«¿Qué dos particularidades tiene Safari en iPhone respecto a la geolocalización en una PWA y por qué fue obligatorio agregar `./geo-helper.js` en `sw.js`?»*

### Qué señalar en el código

- Handler directo de clic en [`app.js` (L119–L122 y L147)](pwa-geo-modular/app.js#L119-L122).
- Arreglo `APP_SHELL` en [`sw.js` (L4–L13)](pwa-geo-modular/sw.js#L4-L13).

### Respuesta de 60 segundos

> En iPhone (iOS / WebKit) hay dos reglas críticas: primero, Safari bloquea o ignora silenciosamente `getCurrentPosition()` si se llama de forma automática al cargar la página (`DOMContentLoaded`); tiene que ejecutarse dentro del evento `click` directo del usuario, como lo hacemos en `#btn-confirmar`. Segundo, Safari y la PWA instalada en pantalla de inicio tienen almacenes de permisos aislados (dar permiso en Safari no lo otorga automáticamente en el icono instalado) e incluye la opción *"Permitir una vez"*.
> Por último, incluimos `./geo-helper.js` en el arreglo `APP_SHELL` de `sw.js` para que el Service Worker lo precachee en `install`; si no estuviera ahí, al abrir la PWA offline `app.js` fallaría porque las funciones del helper no existirían.

---

## Lista de Comprobación Rápida antes de Pasar a Revisión

- [ ] La URL de GitHub Pages abre bajo **HTTPS** tanto en la laptop como en el teléfono móvil.
- [ ] En DevTools $\rightarrow$ **Application** $\rightarrow$ **Cache Storage**, aparece `geo-pwa-modular-v1` conteniendo `index.html`, `styles.css`, `geo-helper.js`, `app.js`, `manifest.json` y los dos iconos.
- [ ] Al abrir la página por primera vez (permiso en `'prompt'`), pulsar **Adjuntar mi ubicación** muestra primero la tarjeta `#card-prepermiso` sin lanzar de golpe el diálogo del navegador.
- [ ] Al pulsar **Compartir mi ubicación**, aparece el diálogo nativo y al aceptar muestra coordenadas, precisión en metros (`± X m`), fecha y enlace funcional a OpenStreetMap.
- [ ] En el teléfono móvil (con GPS activo) muestra la insignia verde **`Precisión GPS Alta`** (`< 30 m`) y en la laptop muestra **`Ubicación Aproximada (Wi-Fi / IP)`** (`>= 30 m`).
- [ ] Al pulsar **Ahora no** o bloquear el permiso de ubicación en el candado de la URL, se activa automáticamente el **Plan B (`#card-manual`)** permitiendo guardar un municipio de forma manual.
