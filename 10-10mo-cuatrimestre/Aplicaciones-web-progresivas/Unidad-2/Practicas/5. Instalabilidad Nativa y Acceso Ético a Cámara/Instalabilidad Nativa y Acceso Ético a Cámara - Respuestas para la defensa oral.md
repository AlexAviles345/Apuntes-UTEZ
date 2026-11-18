# Instalabilidad Nativa y Acceso Ético a Cámara — Respuestas para la Defensa Oral

Esta guía prepara las respuestas y puntos exactos del código que debes señalar durante la revisión presencial en tu teléfono móvil del **Tema 6.1 y 6.2**.

Para revisar primero la explicación detallada de cada archivo, consulta [Instalabilidad Nativa y Acceso Ético a Cámara — Explicación del código](Instalabilidad%20Nativa%20y%20Acceso%20%C3%89tico%20a%20C%C3%A1mara%20-%20Explicaci%C3%B3n%20del%20c%C3%B3digo.md).

---

## Mapa Rápido para Señalar en el Código

| Qué te pide mostrar el profesor | Archivo y líneas |
|---|---|
| Identidad, `display: "standalone"` e iconos con rutas relativas `./` | [`manifest.json` (L1–L15)](pwa-camara-instalable/manifest.json#L1-L15) |
| Vínculo del manifiesto, `theme-color` y `apple-touch-icon` | [`index.html` (L8–L11)](pwa-camara-instalable/index.html#L8-L11) |
| Tarjeta oculta de Pre-Permiso (`#aviso-permiso`) | [`index.html` (L30–L35)](pwa-camara-instalable/index.html#L30-L35) |
| Etiqueta `<video>` con `autoplay playsinline muted` | [`index.html` (L37)](pwa-camara-instalable/index.html#L37) |
| Intercepción de `beforeinstallprompt` y `.prompt()` + `.userChoice` | [`app.js` (L16–L40)](pwa-camara-instalable/app.js#L16-L40) |
| Detección de iOS y modo instalado (`verificarEntornoIOS`) | [`app.js` (L47–L57)](pwa-camara-instalable/app.js#L47-L57) |
| Liberación de hardware con `track.stop()` (`detenerCamaraActiva`) | [`app.js` (L70–L77)](pwa-camara-instalable/app.js#L70-L77) |
| Llamada a `getUserMedia` y diagnóstico de errores en `.catch()` | [`app.js` (L79–L117)](pwa-camara-instalable/app.js#L79-L117) |
| Desacoplamiento en 2 pasos del Pre-Permiso UX | [`app.js` (L120–L128)](pwa-camara-instalable/app.js#L120-L128) |
| Alternancia `'environment'` ↔ `'user'` y apagado de cámara | [`app.js` (L131–L145)](pwa-camara-instalable/app.js#L131-L145) |
| Estrategia Cache First y precarga de iconos en el Service Worker | [`sw.js` (L1–L34)](pwa-camara-instalable/sw.js#L1-L34) |

---

## Pregunta 1: Los Tres Requisitos de Instalabilidad y Rutas en GitHub Pages

> *«¿Qué tres requisitos exige el navegador para considerar instalable tu PWA y por qué todas las rutas del `manifest.json` empiezan con `./`?»*

### Explicación técnica

1. **Los tres requisitos simultáneos:**
   - **HTTPS:** Servirse en un origen seguro (GitHub Pages provee HTTPS automáticamente).
   - **Service Worker activo:** Tener un Service Worker registrado que controle la página y maneje el evento `fetch` ([`sw.js`](pwa-camara-instalable/sw.js)).
   - **Web App Manifest válido:** Contar con [`manifest.json`](pwa-camara-instalable/manifest.json) vinculado en el `<head>`, con `name`/`short_name`, `start_url`, `display: "standalone"` y al menos dos iconos PNG físicos de `192x192` y `512x512` píxeles exactos.

2. **Por qué usamos `./` en lugar de `/`:**
   - En GitHub Pages el proyecto no vive en la raíz del dominio (`https://usuario.github.io/`), sino dentro de un subdirectorio con el nombre del repositorio (`https://usuario.github.io/pwa-camara-instalable/`).
   - Si pusiéramos `/index.html` o `/icons/icon-192.png` (ruta absoluta desde la raíz), el navegador buscaría `https://usuario.github.io/icons/icon-192.png` y devolvería error `404 Not Found`, rompiendo la instalación.
   - Con `./index.html` y `./icons/icon-192.png`, el navegador resuelve las rutas respecto a la carpeta actual del proyecto.

### Respuesta de 60 segundos

> El navegador exige tres condiciones al mismo tiempo: contexto seguro HTTPS, un Service Worker activo con manejador `fetch` y un `manifest.json` con `display: "standalone"` e iconos reales de `192x192` y `512x512`. Usamos `./` en `start_url`, `scope` e `icons` porque en GitHub Pages la app se aloja dentro de un subdirectorio; una barra inicial `/` apuntaría a la raíz del dominio `github.io` y provocaría errores 404 al buscar los iconos o el documento de arranque.

---

## Pregunta 2: El Patrón de Pre-Permiso (UX Ética)

> *«¿Por qué no llamamos a `navigator.mediaDevices.getUserMedia()` directamente en el primer botón o al cargar la página? ¿Qué riesgo técnico evitamos con la tarjeta `#aviso-permiso`?»*

### Qué señalar en el código

En [`app.js` (L120–L128)](pwa-camara-instalable/app.js#L120-L128):

```javascript
// Paso 1: solo muestra el aviso explicativo en el DOM
document.getElementById('btn-preparar-camara').addEventListener('click', () => {
  document.getElementById('aviso-permiso').hidden = false;
});

// Paso 2: cuando el usuario confirma conscientemente, recién se invoca getUserMedia
document.getElementById('btn-confirmar-permiso').addEventListener('click', () => {
  document.getElementById('aviso-permiso').hidden = true;
  iniciarCamara(modoCamaraActual);
});
```

### Explicación técnica

- Si el diálogo nativo del navegador (*"¿Permitir que este sitio use tu cámara?"*) aparece de sorpresa al abrir la página o sin explicar para qué se usará, el usuario suele pulsar **"Bloquear"** por desconfianza.
- **El bloqueo es irreversible desde JavaScript:** Una vez que el usuario bloquea el permiso nativo, el navegador guarda esa decisión y rechaza automáticamente cualquier llamada futura a `getUserMedia()` con `NotAllowedError` sin volver a mostrar la ventana de permiso.
- Con el patrón de **Pre-Permiso**, el primer clic solo destapa una tarjeta HTML controlada por nosotros (`#aviso-permiso`) donde explicamos que la imagen es solo una vista previa local y no se envía a servidores. Solo cuando el usuario está de acuerdo y pulsa *"Aceptar y Encender Cámara"*, invocamos `iniciarCamara()`.

### Respuesta de 60 segundos

> Si disparamos `getUserMedia()` sin contexto y el usuario pulsa "Bloquear" en la ventana nativa del navegador, el bloqueo queda guardado permanentemente y JavaScript ya no puede volver a pedir el permiso; la única forma de revertirlo es que el usuario entre manualmente a los ajustes del navegador. Por eso desacoplamos el flujo en dos clics: `#btn-preparar-camara` solo muestra nuestra tarjeta `#aviso-permiso` explicando que el video es 100% local, y solo cuando el usuario pulsa `#btn-confirmar-permiso` llamamos a `getUserMedia()`.

---

## Pregunta 3: Liberación del Sensor con `track.stop()` al Alternar Cámaras

> *«¿Qué hace exactamente `detenerCamaraActiva()` y qué pasaría en un teléfono móvil si intentas cambiar de la cámara trasera a la frontal sin ejecutar `track.stop()`?»*

### Qué señalar en el código

En [`app.js` (L70–L82)](pwa-camara-instalable/app.js#L70-L82):

```javascript
function detenerCamaraActiva() {
  if (streamActual) {
    streamActual.getTracks().forEach((track) => {
      track.stop();
    });
    streamActual = null;
  }
}
```

Y al inicio de `iniciarCamara(modo)`:

```javascript
function iniciarCamara(modo) {
  detenerCamaraActiva();
  visorVideo.srcObject = null;
  ...
```

### Explicación técnica

1. **Qué hace `track.stop()`:**
   Un `MediaStream` devuelto por `getUserMedia()` contiene una o más pistas (`MediaStreamTrack`). Al recorrer `streamActual.getTracks()` e invocar `track.stop()`, le ordenamos al sistema operativo que cierre el canal de hardware y libere físicamente el sensor de la cámara.
2. **Por qué no basta con hacer `visorVideo.srcObject = null`:**
   Limpiar `srcObject` solo desconecta el elemento `<video>` de la pantalla, pero **la cámara sigue encendida en segundo plano** consumiendo batería y reteniendo el bloqueo del hardware.
3. **Qué ocurre en móviles si no se detiene antes de cambiar de lente:**
   Los sistemas operativos móviles (especialmente iOS/WebKit y muchos dispositivos Android) no permiten que una página web mantenga abiertos los sensores `'environment'` (trasera) y `'user'` (frontal) al mismo tiempo. Si pides el segundo lente sin liberar el primero, `getUserMedia()` rechaza la promesa con `NotReadableError` (*Hardware in use*) o congela el visor.

### Respuesta de 60 segundos

> `detenerCamaraActiva()` recorre todas las pistas del `streamActual` con `getTracks()` y ejecuta `track.stop()` en cada una antes de limpiar la referencia. Esto es indispensable porque en teléfonos móviles el sistema operativo bloquea el hardware de cámara: no puedes abrir el sensor frontal mientras el trasero sigue transmitiendo. Si solo limpiáramos `srcObject = null` sin llamar a `track.stop()`, el sensor seguiría ocupado y al cambiar de cámara la promesa fallaría con `NotReadableError` o dejaría la imagen congelada.

---

## Pregunta 4: Diagnóstico de Errores en `.catch()` (`NotAllowedError` vs. `NotFoundError`)

> *«En el bloque `.catch()` de `iniciarCamara()`, ¿cómo distingues si el fallo fue culpa de un permiso rechazado o de un problema físico del dispositivo?»*

### Qué señalar en el código

En [`app.js` (L106–L116)](pwa-camara-instalable/app.js#L106-L116):

```javascript
    .catch((error) => {
      if (error.name === 'NotAllowedError') {
        actualizarMensajeEstado('Permiso denegado. Habilita el acceso a la cámara en los ajustes de tu navegador.');
      } else if (error.name === 'NotFoundError') {
        actualizarMensajeEstado('No se detectó el sensor de cámara solicitado en este dispositivo.');
      } else if (error.name === 'NotReadableError') {
        actualizarMensajeEstado('La cámara está siendo usada por otra aplicación.');
      } else {
        actualizarMensajeEstado(`Error al acceder al hardware: ${error.message}`);
      }
    });
```

### Tabla de errores de `getUserMedia()`

| `error.name` | Causa real | Mensaje y acción para el usuario |
|---|---|---|
| `NotAllowedError` | El usuario pulsó *"Bloquear"* o el permiso de cámara está denegado en la configuración del navegador o del sistema operativo | Indicarle que debe habilitar el permiso manualmente en los ajustes del navegador |
| `NotFoundError` | El dispositivo no cuenta físicamente con ningún sensor de video que cumpla las restricciones solicitadas | Informar que no se detectó el sensor de cámara en el dispositivo |
| `NotReadableError` | El sensor existe y tiene permiso, pero está bloqueado a nivel de hardware/sistema operativo por otra app o porque no se liberó el track anterior | Informar que la cámara está ocupada por otra aplicación |

---

## Pregunta 5: Intercepción de Instalación (`beforeinstallprompt` vs. iOS/iPhone)

> *«Explica cómo funciona tu botón `#btn-instalar` en Android y por qué tuviste que programar `verificarEntornoIOS()` y la etiqueta `playsinline` para iPhone.»*

### Qué señalar en el código

1. **En Android/Chrome ([`app.js` L16–L40](pwa-camara-instalable/app.js#L16-L40)):**
   - Escuchamos `window.addEventListener('beforeinstallprompt', ...)`.
   - Llamamos a `event.preventDefault()`, guardamos el evento en `eventoInstalacionDiferido` y quitamos el atributo `hidden` de `#btn-instalar`.
   - Al hacer clic en `#btn-instalar`, ejecutamos `eventoInstalacionDiferido.prompt()` y esperamos la promesa `eventoInstalacionDiferido.userChoice.then(...)` para saber si el usuario aceptó (`resultado.outcome === 'accepted'`) y ocultar el botón.

2. **En iPhone / iOS ([`app.js` L47–L57](pwa-camara-instalable/app.js#L47-L57) e [`index.html` L10, L23–L26, L37](pwa-camara-instalable/index.html#L10)):**
   - **Sin `beforeinstallprompt`:** Apple no implementa `beforeinstallprompt` en WebKit; ninguna página puede abrir el diálogo de instalación por código. Por eso `verificarEntornoIOS()` comprueba si el dispositivo es iPhone/iPad (`esIOS`) y si aún no está instalado (`!estaInstalada`), mostrando la tarjeta `#instrucciones-ios` que guía al usuario a pulsar **Compartir $\rightarrow$ Agregar a inicio**.
   - **Icono en pantalla de inicio:** Safari prioriza `<link rel="apple-touch-icon" href="./icons/icon-192.png">` en el `<head>`.
   - **Atributo `playsinline` en `<video>`:** Sin `playsinline`, iOS abre cualquier `<video>` activo en su reproductor nativo a pantalla completa, tapando nuestros botones HTML de cambiar y apagar cámara.

---

## Lista de Comprobación Rápida antes de Pasar a Revisión

- [ ] La URL de GitHub Pages abre con **HTTPS** y muestra `SW registrado` en consola.
- [ ] En DevTools $\rightarrow$ **Application** $\rightarrow$ **Manifest**, aparecen los iconos `192x192` y `512x512` sin errores 404.
- [ ] Al abrir la app, la cámara está apagada y **no** salta ningún permiso nativo de golpe.
- [ ] Al tocar **Solicitar Acceso a Cámara**, primero aparece la tarjeta `#aviso-permiso`.
- [ ] Al tocar **Aceptar y Encender Cámara**, se solicita el permiso nativo y se enciende la cámara trasera (`environment`).
- [ ] Al tocar **Cambiar cámara**, se detiene el sensor anterior (`track.stop()`) y se enciende la cámara frontal (`user`).
- [ ] Al tocar **Apagar cámara**, se apaga el indicador físico de cámara del dispositivo y el visor queda limpio.
