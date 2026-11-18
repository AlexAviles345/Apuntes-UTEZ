# Tema 6.1 y 6.2 - Instalabilidad Nativa (`manifest.json`) y Acceso Ético a Cámara Frontal/Trasera

**Asignatura:** Desarrollo de Aplicaciones Web Progresivas (PWA)

**Restricciones Técnicas Obligatorias:**

1. Código escrito **100% en JavaScript Vanilla**.
2. **Prohibido el uso de `async/await`** y de librerías externas. Toda la asincronía debe resolverse mediante `.then()`, `.catch()` y `.finally()`.
3. Despliegue obligatorio en **GitHub Pages (HTTPS)** y revisión presencial directamente en su teléfono móvil durante la siguiente clase.

---

## 1. Contexto Arquitectónico y Ética de Permisos (UX Consciente)

Para que una aplicación web deje de comportarse como una pestaña más del navegador y se instale como una aplicación nativa en la pantalla de inicio del teléfono, el navegador exige tres requisitos técnicos simultáneos:

1. Servirse bajo **HTTPS** (garantizado por GitHub Pages).
2. Contar con un **Service Worker activo** que controle el ámbito (*scope*) de la página.
3. Declarar un archivo **`manifest.json`** válido con metadatos de identidad, modo de visualización e iconos de alta resolución.

### La Importancia del Consentimiento Consciente antes de Pedir Permisos

Un error grave de diseño en aplicaciones móviles es disparar el cuadro de diálogo nativo del navegador (*"¿Permitir que este sitio use tu cámara?"*) apenas carga la página o mediante un botón ambiguo sin contexto.

- **El riesgo técnico irreversible:** Si el usuario pulsa *"Bloquear"* por desconfianza o sorpresa, el navegador guarda esa decisión a nivel de sistema operativo. A partir de ese momento, JavaScript pierde por completo la capacidad de volver a mostrar la ventana de permiso; la cámara fallará silenciosamente y el usuario tendría que entrar manualmente a la configuración del navegador para desbloquearla.
- **El patrón de Pre-Permiso (UX Ética):** Antes de invocar la API de hardware (`getUserMedia`), tu interfaz debe mostrar un aviso explicativo claro indicando para qué se usará la cámara, qué cámara se encenderá y garantizando que el flujo de video ocurre localmente en el dispositivo. Solo cuando el usuario confirma conscientemente en tu interfaz, se dispara la solicitud nativa del navegador.

---

## 2. Mapa de Archivos del Proyecto

Crea un repositorio en GitHub llamado `pwa-camara-instalable` con la siguiente estructura:

```text
pwa-camara-instalable/
├── index.html
├── styles.css
├── app.js
├── sw.js
├── manifest.json
└── icons/
    ├── icon-192.png     # Obligatorio (192x192 px exactos)
    └── icon-512.png     # Obligatorio (512x512 px exactos)
```

> **Nota sobre Iconos:** Chrome y Android rechazarán la instalación de la PWA si no existen físicamente ambos archivos PNG con las dimensiones exactas (`192x192` y `512x512`) declaradas en el manifiesto.

---

## 3. Fase 1: Configuración de Instalabilidad (`manifest.json` e `index.html`)

### Fragmento A: Anatomía del Manifiesto Web (`manifest.json`)

Analiza cada propiedad de este archivo. Observa que tanto `start_url` como `scope` y las rutas de `icons` utilizan rutas relativas (`./`) para funcionar correctamente dentro del subdirectorio de GitHub Pages:

```json
{
  "name": "Inspección Visual PWA",
  "short_name": "InspecciónPWA",
  "description": "Captura de evidencia fotográfica con acceso consciente a cámara.",
  "start_url": "./index.html",
  "scope": "./",
  "display": "standalone",
  "background_color": "#0f172a",
  "theme_color": "#0f172a",
  "orientation": "portrait",
  "icons": [
    {
      "src": "./icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "./icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

---

### Fragmento B: Captura del Evento de Instalación (`app.js`)

Aunque el navegador muestra un icono de instalación en la barra de direcciones cuando se cumplen los criterios, puedes interceptar el evento `beforeinstallprompt` para ofrecer un botón de instalación propio dentro de tu interfaz:

```jsx
let eventoInstalacionDiferido = null;

window.addEventListener('beforeinstallprompt', (event) => {
  // Evita que el mini-banner automático aparezca antes de tiempo
  event.preventDefault();
  eventoInstalacionDiferido = event;

  // Muestra tu botón personalizado de instalación en la UI
  const btnInstalar = document.getElementById('btn-instalar');
  btnInstalar.hidden = false;
});
```

### Desafío de Ensamblado 1

1. Vincula `<link rel="manifest" href="./manifest.json">` y `<meta name="theme-color" content="#0f172a">` en el `<head>` de `index.html`.
2. Programa el evento `click` del botón `#btn-instalar` para invocar `eventoInstalacionDiferido.prompt()` y encadenar `.userChoice.then((resultado) => ...)` para ocultar el botón una vez aceptada la instalación.
3. Configura un `sw.js` básico con estrategia **Cache First** que precachee `./index.html`, `./styles.css`, `./app.js`, `./manifest.json` y los dos iconos.

---

## 4. Fase 2: Flujo de Pre-Permiso y Control de Cámara (`app.js`)

El acceso al hardware multimedia se realiza mediante `navigator.mediaDevices.getUserMedia()`, una API que solo existe en contextos seguros (HTTPS) y devuelve una Promesa.

### Fragmento C: Liberación de Hardware entre Cambios de Cámara

En teléfonos móviles, no puedes abrir la cámara frontal mientras la cámara trasera sigue transmitiendo; el sistema operativo bloqueará el sensor y rechazará la promesa. Antes de solicitar un nuevo flujo, debes detener todas las pistas (*tracks*) activas:

```jsx
let streamActual = null;
let modoCamaraActual = 'environment'; // 'environment' = trasera | 'user' = frontal

function detenerCamaraActiva(){
  if (streamActual) {
    streamActual.getTracks().forEach((track) => {
      track.stop();
    });
    streamActual = null;
  }
}
```

---

### Fragmento D: Encendido de Cámara con Promesas y Diagnóstico de Errores

Analiza cómo `getUserMedia()` recibe la restricción `facingMode` y cómo el bloque `.catch()` diferencia si el usuario rechazó el permiso (`NotAllowedError`) o si el dispositivo no posee ese lente (`NotFoundError`):

```jsx
function iniciarCamara(modo){
  detenerCamaraActiva();

  const restricciones = {
    video: { facingMode: modo },
    audio: false
  };

  return navigator.mediaDevices.getUserMedia(restricciones)
    .then((stream) => {
      streamActual = stream;
      const visorVideo = document.getElementById('visor-camara');
      visorVideo.srcObject = stream;
      actualizarMensajeEstado(`Cámara activa (${modo === 'environment' ? 'Trasera' : 'Frontal'})`);
    })
    .catch((error) => {
      if (error.name === 'NotAllowedError') {
        actualizarMensajeEstado('Permiso denegado. Habilita el acceso a la cámara en los ajustes de tu navegador.');
      } else if (error.name === 'NotFoundError') {
        actualizarMensajeEstado('No se detectó el sensor de cámara solicitado en este dispositivo.');
      } else {
        actualizarMensajeEstado(`Error al acceder al hardware: ${error.message}`);
      }
    });
}
```

---

### Fragmento E: Flujo de Consentimiento Previo (Pre-Permiso UX)

Observa cómo desacoplamos la intención inicial del usuario de la llamada real al hardware. El primer clic solo despliega una tarjeta informativa explicando el motivo del permiso; el segundo clic confirma el consentimiento y ejecuta `iniciarCamara()`:

```jsx
// Paso 1: El usuario pulsa "Solicitar Acceso a Cámara" -> Mostramos aviso explicativo
document.getElementById('btn-preparar-camara').addEventListener('click', () => {
  document.getElementById('aviso-permiso').hidden = false;
});

// Paso 2: El usuario lee el motivo y pulsa "Aceptar y Encender Cámara"
document.getElementById('btn-confirmar-permiso').addEventListener('click', () => {
  document.getElementById('aviso-permiso').hidden = true;
  iniciarCamara(modoCamaraActual);
});
```

### Desafío de Ensamblado 2 (Estructura HTML y Alternancia de Lentes)

Construye por tu cuenta el esqueleto en `index.html` y la lógica restante en `app.js` cumpliendo con estos puntos:

1. **Etiqueta `<video>` compatible con móviles:** Inserta `<video id="visor-camara" autoplay playsinline muted></video>`. (El atributo `playsinline` es indispensable para que iOS/Safari no abra un reproductor en pantalla completa al encender la cámara).
2. **Tarjeta de Aviso Ético (`#aviso-permiso`):** Crea un contenedor oculto por defecto (`hidden`) que explique al usuario: *"Esta aplicación requiere acceso a tu cámara únicamente para mostrar una vista previa local en pantalla. Ninguna imagen se envía a servidores externos"*, acompañado del botón `#btn-confirmar-permiso`.
3. **Botón de Cambio de Cámara (`#btn-alternar-camara`):** Programa su evento `click` para invertir el valor de `modoCamaraActual` (si es `'environment'` pasa a `'user'` y viceversa) e invocar nuevamente a `iniciarCamara(modoCamaraActual)`.
4. **Botón de Apagado (`#btn-apagar-camara`):** Debe invocar `detenerCamaraActiva()`, limpiar `visorVideo.srcObject = null` y actualizar el mensaje de estado.

---

## 5. Despliegue en GitHub Pages y Verificación en Teléfono Móvil

Antes de la clase presencial, despliega tu repositorio en GitHub Pages y realiza estas pruebas directamente desde el navegador de tu smartphone (Chrome en Android o Safari en iOS):

1. **Auditoría en DevTools (Escritorio):**
   Abre tu URL HTTPS de GitHub Pages $\rightarrow$ `F12` $\rightarrow$ **Application** $\rightarrow$ **Manifest**. Confirma que no existan errores en los iconos ni advertencias de instalabilidad.
2. **Instalación en el Teléfono:**
   Abre tu URL en tu móvil. Pulsa tu botón **Instalar App** (o **Agregar a pantalla de inicio**). Verifica que la aplicación se abra en ventana independiente (`standalone`), sin barra de direcciones del navegador.
3. **Prueba de Consentimiento y Sensores:**
   Pulsa el botón para preparar la cámara, verifica que se muestre el aviso explicativo antes del diálogo nativo del teléfono, otorga el permiso y comprueba la alternancia entre cámara trasera y frontal.

---

# Notas Técnicas: Consideraciones Críticas para Usuarios con iPhone (iOS / WebKit)

Si vas a presentar la práctica en un **iPhone**, debes tomar en cuenta que Apple implementa reglas distintas a las de Android/Chrome en su motor **WebKit**. Si no contemplas estas diferencias en tu código, tu botón de instalación nunca aparecerá y la cámara puede quedar inutilizable en pantalla completa.

### 1. El Botón de Instalación (`beforeinstallprompt` no existe en iOS)

En iOS, Safari (ni Chrome para iOS) **nunca dispara el evento `beforeinstallprompt`**. Apple bloquea por diseño que una página web invoque mediante JavaScript el cuadro nativo de instalación; la instalación siempre debe iniciarla el usuario manualmente desde el menú del navegador.

- **Consecuencia en tu código:** El botón `#btn-instalar` que ocultaste por defecto (`hidden`) permanecerá invisible para siempre en un iPhone.
- **Solución (Detección de plataforma y guía visual):** Si el dispositivo es iOS y la aplicación aún no se está ejecutando en modo instalado (`standalone`), debes mostrar un mensaje instructivo indicando los pasos manuales (**Botón Compartir** $\rightarrow$ **Agregar a inicio**).

#### Fragmento Auxiliar: Detección de iOS y Modo Instalado (`app.js`)

Analiza cómo verificamos si el usuario está en un iPhone/iPad y si abrió la app desde Safari o desde el icono de su pantalla de inicio:

```jsx
function verificarEntornoIOS(){
  const esIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
  const estaInstalada = window.navigator.standalone === true ||
                        window.matchMedia('(display-mode: standalone)').matches;

  // Si está en iPhone y aún la ve desde el navegador, mostrar instrucciones manuales
  if (esIOS && !estaInstalada) {
    const guiaIOS = document.getElementById('instrucciones-ios');
    if (guiaIOS) guiaIOS.hidden = false;
  }
}
```

#### Etiqueta Obligatoria para el Icono en iOS (`index.html`)

Aunque iOS lee el `manifest.json`, para generar correctamente el icono en la pantalla de inicio sigue priorizando la etiqueta propietaria de Apple en el `<head>`. Agrégala usando ruta relativa:

```html
<link rel="apple-touch-icon" href="./icons/icon-192.png">
```

### 2. Acceso a la Cámara (`getUserMedia`) en iPhone

El acceso al hardware multimedia funciona bajo HTTPS en iOS, pero presenta tres comportamientos particulares que debes cuidar:

1. **El secuestro a pantalla completa (`playsinline`):**
   Si colocas únicamente `<video id="visor-camara" autoplay></video>`, en cuanto se encienda la cámara iOS abrirá su reproductor nativo a pantalla completa, ocultando tus botones HTML de *"Cambiar cámara"* y *"Apagar"*. Es obligatorio incluir los tres atributos juntos:
   ```html
   <video id="visor-camara" autoplay playsinline muted></video>
   ```

2. **Aislamiento de permisos entre Safari y la PWA instalada:**
   En iOS, el navegador Safari y la aplicación instalada en la pantalla de inicio (`standalone`) **no comparten el almacenamiento de permisos**. Si otorgaste permiso de cámara en Safari y luego instalas la PWA en tu pantalla de inicio, al abrirla te volverá a pedir permiso de cámara (e incluso puede volver a solicitarlo cada vez que cierres por completo la app instalada). Por eso el aviso previo de consentimiento es aún más importante en iPhone.

3. **Bloqueo estricto al alternar cámara frontal y trasera:**
   WebKit no permite inicializar `facingMode: 'user'` mientras el sensor `'environment'` sigue activo; si no ejecutas `track.stop()` antes de llamar nuevamente a `getUserMedia()`, la promesa será rechazada con un error `NotReadableError` o quedará congelada. Asegúrate de que tu función `detenerCamaraActiva()` se ejecute siempre antes de solicitar el cambio de lente.

### Checklist de Verificación en iPhone antes de Clase

- **En `index.html`:** Incluye `<link rel="apple-touch-icon" href="./icons/icon-192.png">` y asegúrate de que la etiqueta `<video>` tenga `autoplay playsinline muted`.
- **En `app.js`:** Incluye un contenedor `#instrucciones-ios` (oculto por defecto) que se muestre únicamente cuando `esIOS && !estaInstalada` sea verdadero, explicando: *"Para instalar en iPhone, pulsa el icono Compartir y selecciona 'Agregar a inicio'"*.
- **Prueba real en el teléfono:** Abre tu enlace de **GitHub Pages** en Safari, instálalo en tu pantalla de inicio, ábrelo desde el icono nuevo y verifica que abra sin barra de navegación y que puedas alternar ambas cámaras.
