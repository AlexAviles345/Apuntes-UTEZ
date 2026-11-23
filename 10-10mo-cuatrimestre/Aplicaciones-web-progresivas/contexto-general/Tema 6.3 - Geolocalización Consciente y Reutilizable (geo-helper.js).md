# Tema 6.3 - Geolocalización Consciente y Reutilizable (`geo-helper.js`)

**Asignatura:** Desarrollo de Aplicaciones Web Progresivas (PWA)

**Restricciones Técnicas Obligatorias:**

1. Código escrito **100% en JavaScript Vanilla**.
2. **Prohibido el uso de `async/await`** y de librerías externas. La asincronía debe encapsularse con `new Promise()` y consumirse con `.then()` y `.catch()`.
3. Despliegue obligatorio bajo HTTPS en **GitHub Pages**.

---

## 1. Fundamentos Teóricos de la Geolocation API

La API nativa `navigator.geolocation` permite obtener las coordenadas geográficas del dispositivo. Al igual que IndexedDB, fue diseñada antes de la estandarización de las Promesas en JavaScript, por lo que **funciona mediante callbacks tradicionales** (`successCallback` y `errorCallback`).

### Métodos Principales

- **`getCurrentPosition(exito, error, opciones)`:** Realiza una lectura única de la posición actual. Es el método ideal para etiquetar un reporte, registrar una asistencia o centrar un mapa sin drenar la batería.
- **`watchPosition(exito, error, opciones)`:** Abre un canal continuo que dispara el callback cada vez que el dispositivo detecta movimiento (útil para navegación giro a giro, pero de alto consumo energético). Devuelve un `watchId` que debe cerrarse con `navigator.geolocation.clearWatch(watchId)`.

### Anatomía de la Respuesta (`GeolocationPosition`)

Cuando la lectura tiene éxito, el navegador entrega un objeto con dos propiedades:

1. **`position.timestamp`:** Marca de tiempo exacta en milisegundos en que se fijó la coordenada.
2. **`position.coords`:**
   - `latitude` y `longitude`: Coordenadas en grados decimales (WGS84).
   - `accuracy`: **Margen de error en metros** (radio de confianza del 95%). *Nunca confíes ciegamente en una coordenada sin evaluar su `accuracy`.*
   - `altitude`, `heading` y `speed`: Disponibles únicamente si el hardware cuenta con chip GNSS/GPS activo y está en movimiento (devuelven `null` en computadoras de escritorio).

### Parámetros de Configuración (`PositionOptions`)

```javascript
const opcionesDefault = {
  enableHighAccuracy: true, // Solicita máxima precisión (chip GPS si existe)
  timeout: 10000,           // Tiempo máximo de espera (ms) antes de lanzar error TIMEOUT
  maximumAge: 0             // 0 obliga a lectura fresca; >0 permite reutilizar caché del SO
};
```

---

## 2. Comportamiento por Plataforma y Hardware (Android vs. iOS vs. Sin GPS)

Un error común en desarrollo web es asumir que `getCurrentPosition()` se comporta igual en todos los dispositivos. La precisión, el consumo y las reglas de permisos cambian drásticamente según el sistema operativo y la presencia de hardware satelital:

| Dimensión Técnica | Android (Chrome / WebView) | iOS / iPhone (Safari / WebKit) | Equipos sin GPS (Laptops / Desktops) |
| --- | --- | --- | --- |
| **Fuente de ubicación** | Híbrida: Satélites GPS/GNSS + torres celulares + redes Wi-Fi cercanas. | Híbrida: CoreLocation (GPS + Wi-Fi + Bluetooth + red celular). | **Triangulación Wi-Fi (MAC/BSSID)** y enrutamiento por **Dirección IP**. |
| **Margen de error (`accuracy`)** | 3 m – 15 m en exteriores; 15 m – 50 m en interiores. | 5 m – 20 m en exteriores; 20 m – 65 m en interiores. | **30 m – 300 m** con Wi-Fi; **1,000 m – 10,000 m** si solo depende de IP (cable/Ethernet). |
| **Disparo sin clic previo** | Permitido (aunque desaconsejado por UX). | **Bloqueado o ignorado con frecuencia** si no nace de un toque/clic directo del usuario. | Permitido bajo HTTPS. |
| **Granularidad de permiso** | El usuario puede elegir entre ubicación **Precisa** o **Aproximada** (Android 12+). | Incluye opción **"Permitir una vez"** (pide permiso de nuevo en la siguiente sesión). | Permiso estándar por dominio (`Permitir` / `Bloquear`). |
| **Aislamiento en PWA instalada** | Comparte permisos con Chrome. | **Permisos aislados:** Safari y la PWA instalada en inicio tienen almacenes separados. | Comparte permisos con el navegador base. |

### Puntos Críticos que Debes Considerar en Producción

1. **La trampa de `enableHighAccuracy: true` en computadoras sin GPS:**
   En una laptop sin chip GPS, activar `enableHighAccuracy: true` no crea precisión satelital de la nada; solo obliga al sistema operativo a escanear tarjetas Wi-Fi durante más tiempo. Si el equipo está conectado por cable Ethernet o en una red corporativa sin mapeo Wi-Fi, la petición tardará varios segundos y con frecuencia terminará en error `TIMEOUT` (código `3`).
2. **La regla del gesto de usuario en iOS:**
   Si llamas a `getCurrentPosition()` automáticamente dentro de `DOMContentLoaded`, Safari en iPhone suele rechazar silenciosamente la petición o mostrar comportamientos erráticos. La solicitud siempre debe ejecutarse como respuesta directa a un `click` del usuario.

---

## 3. UX No Invasiva y Consentimiento Ético (Patrón Pre-Permiso)

Al igual que ocurre con la cámara, **si disparas el diálogo nativo de ubicación apenas abre la aplicación, el usuario lo bloqueará por instinto**. Una vez bloqueado (`PERMISSION_DENIED`), JavaScript no puede volver a abrir el cuadro de diálogo del sistema.

### Flujo de UX Ética en 3 Pasos

1. **Explicación Contextual (Pre-Permiso):** Antes de tocar `navigator.geolocation`, muestra una tarjeta en tu interfaz explicando el beneficio concreto para el usuario (*"Necesitamos tu ubicación aproximada para adjuntar las coordenadas al reporte técnico y calcular la sucursal más cercana"*).
2. **Activación Bajo Demanda:** Solo cuando el usuario presiona *"Compartir mi ubicación"*, invocas tu módulo reutilizable de geolocalización.
3. **Plan B Obligatorio (Degradación Elegante):** Si el usuario rechaza el permiso, si está en una PC sin GPS o si ocurre un `TIMEOUT`, **la aplicación nunca debe quedar bloqueada**. Debes habilitar inmediatamente un selector manual de zona/ciudad o captura de dirección.

---

## 4. Arquitectura Modular: Construcción de `geo-helper.js`

Para evitar repetir callbacks anidados en cada pantalla o formulario de tu PWA, encapsularemos toda la lógica de geolocalización en un módulo independiente (`geo-helper.js`). De esta forma, cualquier función de `app.js` (un formulario de incidencias, un módulo de check-in o un filtro de mapas) podrá reutilizarlo con una sola línea: `obtenerUbicacionActual().then(...)`.

### Estructura de Archivos

```text
pwa-geo-modular/
├── index.html
├── styles.css
├── geo-helper.js    # Módulo reutilizable de geolocalización (Promisificado)
├── app.js           # Lógica de UI, pre-permiso y consumo del helper
├── sw.js            # Service Worker (incluir ./geo-helper.js en App Shell)
└── manifest.json
```

---

### Fragmento A: Encapsulamiento Promisificado y Traducción de Errores (`geo-helper.js`)

Analiza cómo este archivo traduce los códigos numéricos nativos (`1`, `2`, `3`) a mensajes claros y normaliza el objeto de salida para que cualquier módulo consumidor reciba siempre la misma estructura:

```javascript
// geo-helper.js - Módulo reutilizable de geolocalización en Vanilla JS

function traducirErrorGeolocalizacion(error) {
  switch (error.code) {
    case 1: // error.PERMISSION_DENIED
      return 'Permiso de ubicación denegado. Puedes ingresar tu zona manualmente.';
    case 2: // error.POSITION_UNAVAILABLE
      return 'No fue posible determinar tu ubicación (señal GPS o Wi-Fi no disponible).';
    case 3: // error.TIMEOUT
      return 'Se agotó el tiempo de espera intentando obtener las coordenadas.';
    default:
      return 'Ocurrió un error inesperado al consultar la ubicación.';
  }
}

function obtenerUbicacionActual(opcionesPersonalizadas) {
  const opciones = Object.assign(
    {
      enableHighAccuracy: true,
      timeout: 8000,
      maximumAge: 30000 // Acepta una lectura reciente de hasta 30 segundos
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
        reject(new Error(traducirErrorGeolocalizacion(error)));
      },
      opciones
    );
  });
}
```

---

### Fragmento B: Inspección Previa del Estado del Permiso (`geo-helper.js`)

Antes de mostrar la tarjeta de pre-permiso, podemos consultar la **Permissions API** para saber si el usuario ya había otorgado o bloqueado el permiso anteriormente. Observa cómo protegemos la llamada porque algunos navegadores antiguos o entornos restringidos no la soportan de la misma manera:

```javascript
function consultarEstadoPermisoGeo() {
  if (!('permissions' in navigator)) {
    return Promise.resolve('prompt');
  }

  return navigator.permissions.query({ name: 'geolocation' })
    .then((resultado) => resultado.state) // 'granted', 'denied' o 'prompt'
    .catch(() => 'prompt');
}
```

---

### Fragmento C: Reutilización desde Múltiples Funciones en `app.js`

Gracias a que `geo-helper.js` expone funciones puras basadas en promesas, cualquier flujo de negocio en `app.js` puede consumirlo sin conocer los detalles internos de `navigator.geolocation`:

```javascript
// Ejemplo de uso 1: Adjuntar coordenadas al enviar un reporte técnico
function enviarReporteConUbicacion(datosFormulario) {
  mostrarCargando('Obteniendo coordenadas...');

  return obtenerUbicacionActual({ enableHighAccuracy: true, timeout: 7000 })
    .then((ubicacion) => {
      const paqueteCompleto = Object.assign({}, datosFormulario, {
        coordenadas: ubicacion
      });
      console.log('Paquete listo para enviar o encolar en IndexedDB:', paqueteCompleto);
      renderizarResultadoUbicacion(ubicacion);
    })
    .catch((error) => {
      console.warn('[Geo] Fallback activado:', error.message);
      mostrarMensajeError(error.message);
      habilitarSelectorManualZona(); // Plan B sin bloquear al usuario
    });
}

// Ejemplo de uso 2: Lectura rápida de baja precisión para filtrar sucursales cercanas
function buscarSucursalesCercanas() {
  return obtenerUbicacionActual({ enableHighAccuracy: false, maximumAge: 60000 })
    .then((ubicacion) => {
      console.log(`Filtrando sucursales cerca de ${ubicacion.latitud}, ${ubicacion.longitud}`);
    });
}
```

---

### Desafío de Ensamblado Autónomo

Construye una interfaz funcional y súbela a **GitHub Pages** cumpliendo con estos requisitos:

1. **Orden de carga en `index.html`:** Importa `<script src="./geo-helper.js"></script>` antes de `<script src="./app.js"></script>` y asegúrate de incluir `./geo-helper.js` dentro de la lista de activos precacheados en `sw.js`.
2. **Flujo de Pre-Permiso:** Crea un botón *"Adjuntar mi ubicación"*. Al pulsarlo, consulta `consultarEstadoPermisoGeo().then((estado) => ...)`:
   - Si `estado === 'granted'`, llama directamente a `obtenerUbicacionActual()`.
   - Si `estado === 'prompt'`, despliega una tarjeta informativa explicando por qué se solicita la ubicación y muestra el botón de confirmación que dispara la lectura real.
   - Si `estado === 'denied'`, muestra directamente el selector manual de zona e indica cómo reactivar el permiso en el navegador.
3. **Indicador de Calidad de Señal:** Muestra en pantalla el valor de `precisionMetros` (`coords.accuracy`) acompañado de una etiqueta visual: *"Precisión GPS Alta"* si es menor a 30 metros, o *"Ubicación Aproximada (Wi-Fi / IP)"* si es mayor.
