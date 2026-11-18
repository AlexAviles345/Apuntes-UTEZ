# Instalabilidad Nativa y Acceso Ético a Cámara — Explicación del Código

Esta guía explica la arquitectura y cada archivo del proyecto [`pwa-camara-instalable/`](pwa-camara-instalable/), que convierte la aplicación web en una **PWA instalable en pantalla de inicio** (`standalone`) y controla los sensores de **cámara trasera y frontal** mediante un patrón de **consentimiento consciente (Pre-Permiso UX)** usando exclusivamente promesas en JavaScript Vanilla (`.then()`, `.catch()` y `.finally()`).

Para estudiar los escenarios y preguntas de revisión presencial en clase, consulta [Instalabilidad Nativa y Acceso Ético a Cámara — Respuestas para la defensa oral](Instalabilidad%20Nativa%20y%20Acceso%20%C3%89tico%20a%20C%C3%A1mara%20-%20Respuestas%20para%20la%20defensa%20oral.md).

---

## Archivos de la Práctica

| Archivo | Responsabilidad |
|---|---|
| [`index.html`](pwa-camara-instalable/index.html) | Vincula el manifiesto e iconos, define los botones de instalación, la guía iOS, la tarjeta de pre-permiso, el `<video>` y los controles de cámara |
| [`styles.css`](pwa-camara-instalable/styles.css) | Define la regla `[hidden]`, el diseño móvil centrado y el contenedor de video |
| [`manifest.json`](pwa-camara-instalable/manifest.json) | Declara la identidad de la PWA, `display: "standalone"`, orientación vertical, colores y rutas relativas a los iconos `192x192` y `512x512` |
| [`sw.js`](pwa-camara-instalable/sw.js) | Precarga el App Shell y los iconos en `install`, limpia cachés antiguas en `activate` y responde con estrategia *Cache First* en `fetch` |
| [`app.js`](pwa-camara-instalable/app.js) | Registra el Service Worker, gestiona `beforeinstallprompt`, detecta iOS, implementa el flujo de pre-permiso y controla el ciclo de vida del `MediaStream` |
| [`icons/icon-192.png`](pwa-camara-instalable/icons/icon-192.png) | Icono PNG físico de `192x192` píxeles exactos |
| [`icons/icon-512.png`](pwa-camara-instalable/icons/icon-512.png) | Icono PNG físico de `512x512` píxeles exactos |

---

## 1. Requisitos de Instalabilidad de una PWA

Para que un navegador móvil permita instalar una aplicación web en la pantalla de inicio y abrirla como aplicación independiente (`standalone`), deben cumplirse tres pilares simultáneos:

```text
1. Contexto seguro (HTTPS o localhost)
           +
2. Service Worker registrado y activo con manejador fetch
           +
3. manifest.json válido con start_url, display: standalone e iconos 192x192 y 512x512
           ↓
   El navegador habilita la instalabilidad (beforeinstallprompt en Android/Chrome)
```

---

## 2. `manifest.json`: Identidad y Empaquetado Visual

El archivo [`manifest.json`](pwa-camara-instalable/manifest.json) le indica al sistema operativo cómo debe verse y comportarse la aplicación una vez instalada:

```json
{
  "name": "PWA Cámara Instalable",
  "short_name": "CamaraPWA",
  "description": "PWA instalable con acceso ético a la cámara - Alexandro Jesus Ceron Aviles",
  "start_url": "./index.html",
  "scope": "./",
  "display": "standalone",
  "orientation": "portrait",
  "background_color": "#ffffff",
  "theme_color": "#0d6efd",
  "icons": [
    { "src": "./icons/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any" },
    { "src": "./icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any" }
  ]
}
```

### Propiedades clave

| Propiedad | Valor | Función técnica |
|---|---|---|
| `name` | `"PWA Cámara Instalable"` | Nombre completo que aparece en el diálogo de instalación y en la pantalla de carga (*Splash Screen*) |
| `short_name` | `"CamaraPWA"` | Nombre corto que se muestra debajo del icono en la pantalla de inicio del teléfono |
| `start_url` | `"./index.html"` | Documento inicial que abre la PWA al tocar su icono. Usa `./` para no romper la ruta del subdirectorio en GitHub Pages |
| `scope` | `"./"` | Delimita las rutas que pertenecen a la aplicación instalada |
| `display` | `"standalone"` | Oculta la barra de direcciones y pestañas del navegador para que se vea como una app nativa |
| `orientation` | `"portrait"` | Fija la orientación vertical por defecto |
| `background_color` | `"#ffffff"` | Color de fondo del *Splash Screen* mientras carga el documento inicial |
| `theme_color` | `"#0d6efd"` | Color de la barra de estado superior del sistema operativo |
| `icons` | `192x192` y `512x512` | Android utiliza `192x192` para el icono del escritorio y `512x512` para el *Splash Screen* |

---

## 3. `index.html`: Metadatos, Pre-Permiso y Etiqueta `<video>`

### Metadatos en `<head>`

```html
<link rel="manifest" href="./manifest.json">
<meta name="theme-color" content="#0d6efd">
<link rel="apple-touch-icon" href="./icons/icon-192.png">
<meta name="apple-mobile-web-app-capable" content="yes">
```

- `<link rel="manifest" href="./manifest.json">`: conecta el documento HTML con el manifiesto web.
- `<meta name="theme-color" content="#0d6efd">`: colorea la barra del navegador en coincidencia con el manifiesto.
- `<link rel="apple-touch-icon" href="./icons/icon-192.png">`: etiqueta propietaria que iOS/Safari utiliza para generar el icono en la pantalla de inicio del iPhone.
- `<meta name="apple-mobile-web-app-capable" content="yes">`: habilita el modo pantalla completa cuando se agrega a inicio en iOS.

### Componentes interactivos del `<main>`

1. **Botón de instalación en Android/Chrome (`#btn-instalar`)**:
   ```html
   <button id="btn-instalar" hidden>📲 Instalar App</button>
   ```
   Permanece oculto (`hidden`) hasta que el navegador dispara `beforeinstallprompt`.

2. **Tarjeta de instrucciones manuales para iPhone (`#instrucciones-ios`)**:
   ```html
   <div id="instrucciones-ios" class="tarjeta" hidden>
     Para instalar en iPhone, pulsa el icono <strong>Compartir</strong>
     y selecciona <strong>'Agregar a inicio'</strong>.
   </div>
   ```
   Permanece oculta por defecto y solo se muestra si `verificarEntornoIOS()` detecta un iPhone/iPad no instalado.

3. **Flujo de Pre-Permiso (`#btn-preparar-camara` y `#aviso-permiso`)**:
   ```html
   <button id="btn-preparar-camara">Solicitar Acceso a Cámara</button>

   <div id="aviso-permiso" class="tarjeta" hidden>
     <p>Esta aplicación requiere acceso a tu cámara únicamente para mostrar
     una vista previa local en pantalla. Ninguna imagen se envía a
     servidores externos.</p>
     <button id="btn-confirmar-permiso">Aceptar y Encender Cámara</button>
   </div>
   ```
   Separa la solicitud de permiso en dos pasos para que el usuario entienda por qué se encenderá la cámara antes de que aparezca la ventana nativa del navegador.

4. **Visor de video compatible con iOS y Android (`#visor-camara`)**:
   ```html
   <video id="visor-camara" autoplay playsinline muted></video>
   ```
   - `autoplay`: reproduce el flujo de video en cuanto se asigna `srcObject`.
   - `playsinline`: **crítico en iOS/Safari**; evita que el iPhone secuestre el video abriendo un reproductor en pantalla completa que taparía los botones de control.
   - `muted`: permite que la reproducción automática inicie sin bloqueos de políticas de audio del navegador.

---

## 4. `sw.js`: App Shell con Estrategia Cache First

El Service Worker [`sw.js`](pwa-camara-instalable/sw.js) cumple dos objetivos: satisfacer el requisito de instalabilidad del navegador y permitir que la interfaz cargue instantáneamente incluso sin conexión.

```javascript
const CACHE = 'camara-pwa-v3';
const ARCHIVOS = [
  './index.html',
  './styles.css',
  './app.js',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png'
];
```

### Ciclo de vida del Service Worker

| Evento | Qué ejecuta | Por qué es importante |
|---|---|---|
| `install` | `caches.open(CACHE).then((cache) => cache.addAll(ARCHIVOS)).then(() => self.skipWaiting())` | Descarga y almacena en Cache Storage todo el App Shell y los dos iconos PNG |
| `activate` | Filtra `claves.filter((clave) => clave !== CACHE)` y borra versiones viejas, seguido de `self.clients.claim()` | Limpia cachés obsoletas y toma el control inmediato de las pestañas abiertas |
| `fetch` | `caches.match(event.request).then((respuesta) => respuesta \|\| fetch(event.request))` | Estrategia **Cache First**: sirve los archivos estáticos desde el caché local y solo sale a la red si el recurso no está cacheado |

---

## 5. `app.js`: Instalación, Detección iOS y Control de Hardware

### 5.1 Registro del Service Worker

```javascript
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('./sw.js')
    .then((registro) => {
      console.log('SW registrado, scope:', registro.scope);
    })
    .catch((error) => {
      console.error('Error al registrar el SW:', error);
    });
}
```

Se registra con ruta relativa `./sw.js` para que el ámbito (*scope*) coincida con el subdirectorio del repositorio en GitHub Pages.

---

### 5.2 Flujo de Instalación en Android / Chrome (`beforeinstallprompt`)

```javascript
let eventoInstalacionDiferido = null;
const btnInstalar = document.getElementById('btn-instalar');

window.addEventListener('beforeinstallprompt', (event) => {
  event.preventDefault();
  eventoInstalacionDiferido = event;
  btnInstalar.hidden = false;
});
```

1. Cuando Chrome detecta que la página cumple los criterios de instalabilidad (HTTPS + SW + Manifest con iconos válidos), dispara `beforeinstallprompt`.
2. `event.preventDefault()` evita que el navegador muestre su aviso automático de inmediato.
3. Guardamos el evento en `eventoInstalacionDiferido` y mostramos `#btn-instalar`.

Cuando el usuario pulsa `#btn-instalar`:

```javascript
btnInstalar.addEventListener('click', () => {
  if (!eventoInstalacionDiferido) return;

  eventoInstalacionDiferido.prompt();
  eventoInstalacionDiferido.userChoice
    .then((resultado) => {
      if (resultado.outcome === 'accepted') {
        btnInstalar.hidden = true;
      }
    })
    .catch((error) => {
      console.error('Error en la instalación:', error);
    })
    .finally(() => {
      eventoInstalacionDiferido = null;
    });
});
```

- `eventoInstalacionDiferido.prompt()` abre la ventana nativa de instalación del sistema operativo.
- `eventoInstalacionDiferido.userChoice` es una Promesa que resuelve con `{ outcome: 'accepted' | 'dismissed' }`.
- Un evento `beforeinstallprompt` solo puede usarse una vez; por eso en `.finally()` se limpia `eventoInstalacionDiferido = null`.
- Además, el evento `window.addEventListener('appinstalled', ...)` asegura que el botón se oculte si el usuario instala la app desde el menú del navegador.

---

### 5.3 Detección de iPhone / iPad (`verificarEntornoIOS`)

Dado que WebKit en iOS **nunca dispara `beforeinstallprompt`**, la función `verificarEntornoIOS()` detecta si el navegador corre en iOS y si aún no está en modo `standalone`:

```javascript
function verificarEntornoIOS() {
  const esIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
  const estaInstalada = window.navigator.standalone === true ||
                        window.matchMedia('(display-mode: standalone)').matches;

  if (esIOS && !estaInstalada) {
    const guiaIOS = document.getElementById('instrucciones-ios');
    if (guiaIOS) guiaIOS.hidden = false;
  }
}
verificarEntornoIOS();
```

- Si el usuario abre la URL desde Safari en iPhone (`esIOS && !estaInstalada`), se hace visible la tarjeta `#instrucciones-ios`.
- Una vez que el usuario la agrega a su pantalla de inicio y la abre desde el icono, `window.navigator.standalone` es `true`, por lo que las instrucciones ya no aparecen.

---

### 5.4 Liberación del Sensor (`detenerCamaraActiva`)

```javascript
let streamActual = null;
let modoCamaraActual = 'environment'; // 'environment' = trasera | 'user' = frontal

function detenerCamaraActiva() {
  if (streamActual) {
    streamActual.getTracks().forEach((track) => {
      track.stop();
    });
    streamActual = null;
  }
}
```

Un objeto `MediaStream` contiene pistas de hardware (`MediaStreamTrack`). En dispositivos móviles, el sistema operativo bloquea el sensor activo; si intentas abrir la cámara frontal mientras la trasera sigue abierta sin haber llamado a `track.stop()`, `getUserMedia()` falla con `NotReadableError` o deja el video congelado. Además, `track.stop()` apaga físicamente el LED/indicador de cámara del teléfono.

---

### 5.5 Encendido de Cámara y Diagnóstico de Errores (`iniciarCamara`)

```javascript
function iniciarCamara(modo) {
  detenerCamaraActiva();
  visorVideo.srcObject = null;

  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    actualizarMensajeEstado('Este navegador o contexto no soporta acceso a la cámara (se requiere HTTPS).');
    return Promise.resolve();
  }

  const restricciones = { video: { facingMode: { ideal: modo } }, audio: false };

  return navigator.mediaDevices.getUserMedia(restricciones)
    .then((stream) => {
      streamActual = stream;
      visorVideo.srcObject = stream;
      ...
      actualizarMensajeEstado(`Cámara activa (${modo === 'environment' ? 'Trasera' : 'Frontal'})`);
    })
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
}
```

#### Flujo paso a paso de `iniciarCamara(modo)`

```text
1. detenerCamaraActiva() libera cualquier pista previa con track.stop()
2. Verifica que exista navigator.mediaDevices.getUserMedia (requiere HTTPS)
3. Solicita video con facingMode ('environment' o 'user') y audio: false
4. Si la promesa se resuelve (.then):
   ├── Guarda la referencia en streamActual
   ├── Conecta el flujo al elemento <video> (visorVideo.srcObject = stream)
   └── Muestra en #estado qué cámara está activa (Trasera o Frontal)
5. Si la promesa se rechaza (.catch):
   └── Clasifica error.name (NotAllowedError, NotFoundError, NotReadableError)
```

---

### 5.6 Pre-Permiso, Alternancia de Lentes y Apagado

```javascript
// Paso 1: Mostrar aviso ético sin tocar aún el hardware
document.getElementById('btn-preparar-camara').addEventListener('click', () => {
  document.getElementById('aviso-permiso').hidden = false;
});

// Paso 2: Confirmación consciente del usuario -> llamar a getUserMedia
document.getElementById('btn-confirmar-permiso').addEventListener('click', () => {
  document.getElementById('aviso-permiso').hidden = true;
  iniciarCamara(modoCamaraActual);
});

// Alternar entre cámara trasera ('environment') y frontal ('user')
document.getElementById('btn-alternar-camara').addEventListener('click', () => {
  if (!streamActual) {
    actualizarMensajeEstado('Primero enciende la cámara con "Solicitar Acceso a Cámara".');
    return;
  }
  modoCamaraActual = (modoCamaraActual === 'environment') ? 'user' : 'environment';
  iniciarCamara(modoCamaraActual);
});

// Apagar cámara y liberar el hardware
document.getElementById('btn-apagar-camara').addEventListener('click', () => {
  detenerCamaraActiva();
  visorVideo.srcObject = null;
  actualizarMensajeEstado('Cámara apagada.');
});
```

---

## 6. Diagrama de Flujo Completo

```text
Usuario abre la PWA
  ├── En Android/Chrome: se dispara beforeinstallprompt → muestra #btn-instalar
  └── En iPhone/Safari:  verificarEntornoIOS()          → muestra #instrucciones-ios

Usuario pulsa "Solicitar Acceso a Cámara" (#btn-preparar-camara)
  └── Se muestra tarjeta #aviso-permiso (NO se llama a getUserMedia todavía)

Usuario lee el aviso y pulsa "Aceptar y Encender Cámara" (#btn-confirmar-permiso)
  ├── Se oculta #aviso-permiso
  └── iniciarCamara('environment')
        ├── detenerCamaraActiva()
        └── navigator.mediaDevices.getUserMedia({ video: ..., audio: false })
              ├── Permiso concedido (.then) → visorVideo.srcObject = stream
              └── Permiso rechazado (.catch) → muestra mensaje según error.name

Usuario pulsa "Cambiar cámara" (#btn-alternar-camara)
  ├── Invierte modoCamaraActual ('environment' ↔ 'user')
  └── iniciarCamara(modoCamaraActual)
        ├── detenerCamaraActiva() (track.stop() libera el lente anterior)
        └── getUserMedia() abre el nuevo lente

Usuario pulsa "Apagar cámara" (#btn-apagar-camara)
  ├── detenerCamaraActiva() (track.stop() apaga físicamente el sensor)
  ├── visorVideo.srcObject = null
  └── Estado: "Cámara apagada."
```
