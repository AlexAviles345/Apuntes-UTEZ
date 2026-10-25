# ema 2.4 - Arquitectura Mínima de una PWA

## Guía de la fuente

> Para construir una PWA básica utilizando únicamente JavaScript nativo, es necesario establecer una estructura mínima de archivos compuesta por una página principal, una hoja de estilos, un script de control y un archivo de configuración. Este último archivo, conocido como manifiesto, contiene los metadatos indispensables que permiten al navegador transformar la plataforma web en una aplicación instalable con apariencia nativa. Además, para probar el funcionamiento correcto de estos elementos y evitar bloqueos por parte del navegador, resulta indispensable levantar un servidor local mediante la terminal.

---

**Duración estimada:** 20 a 25 minutos (Teoría y Práctica)

**Objetivo de Aprendizaje:** Estructurar la arquitectura de archivos base de una PWA en JavaScript Vanilla, configurar el archivo de manifiesto (manifest.json) e inicializar la aplicación desde un servidor local vía CLI.

## 1. Desarrollos Conceptuales y Guión de Exposición

### A. Anatomía Mínima de Archivos

Una PWA en Vanilla JS no requiere empaquetadores complejos (como Webpack, Vite o Parcel) para comprender su arquitectura fundamental. Su estructura base se compone de cuatro archivos esenciales:

```text
/mi-pwa-base
├── index.html         # Punto de entrada HTML5 y enlace a metadata
├── styles.css         # Estilos UI e indicadores visuales de red
├── app.js             # Lógica cliente, detección de APIs y registro SW
└── manifest.json      # Metadatos de instalación y configuración visual
```

### B. El Manifiesto de la Aplicación Web (manifest.json)

Es un archivo en formato JSON que le indica al navegador cómo debe comportarse la aplicación cuando el usuario decide instalarla en su dispositivo móvil o de escritorio.

#### Propiedades Obligatorias para Instalabilidad:

- **name:** Nombre completo de la aplicación (ej. "Gestor de Inspecciones").
- **short_name:** Nombre corto mostrado debajo del ícono en la pantalla de inicio (máx. 12 caracteres).
- **start_url:** Ruta de arranque al abrir la app instalada (habitualmente ./ o index.html).
- **display:** Modo de visualización. standalone elimina la barra de navegación del navegador, haciendo que parezca una app nativa.
- **background_color:** Color de fondo de la pantalla de carga (Splash Screen).
- **theme_color:** Color de la barra de estado del sistema operativo.
- **icons:** Arreglo de objetos con las rutas y tamaños de los íconos (requiere al menos tamaños de 192x192 px y 512x512 px).

### C. Invocación de Servidores Locales vía CLI

Dado que las PWAs no se ejecutan bajo el protocolo file://, el desarrollador debe dominar el levantamiento de servidores estáticos desde la terminal:

```bash
# Opción 1: Mediante paquete global de Node.js (http-server)
npx http-server -p 8080 -c-1

# Opción 2: Mediante Python 3 (Sin necesidad de Node.js)
python -m http.server 8080
```

La bandera -c-1 en http-server deshabilita la caché HTTP en el servidor para evitar que los archivos modificados queden atrapados en la memoria del navegador durante el desarrollo.

## 2. Implementación de Código Base (Código de Referencia)

### `index.html`

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="theme-color" content="#2c3e50">
  <title>PWA Mínima - Semana 2</title>
  
  <link rel="stylesheet" href="styles.css">
  <!-- Vinculación del Manifiesto Web -->
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <main class="container">
    <h1>Arquitectura Base PWA</h1>
    <div id="estado-red" class="status-box">Comprobando estado...</div>
    <div id="soporte-sw" class="status-box">Verificando Service Worker...</div>
  </main>

  <script src="app.js"></script>
</body>
</html>
```

### `manifest.json`

```json
{
  "name": "Aplicación Web Progresiva Base",
  "short_name": "PWABase",
  "start_url": "./index.html",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#2c3e50",
  "orientation": "portrait",
  "icons": [
    {
      "src": "https://via.placeholder.com/192",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "https://via.placeholder.com/512",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### `app.js`

```javascript
// 1. Detección de Estado de Red
const divEstadoRed = document.getElementById('estado-red');

function actualizarEstadoRed() {
  if (navigator.onLine) {
    divEstadoRed.textContent = '🟢 Estado: En línea (Online)';
    divEstadoRed.className = 'status-box online';
  } else {
    divEstadoRed.textContent = '🔴 Estado: Sin conexión (Offline)';
    divEstadoRed.className = 'status-box offline';
  }
}

// Escuchar eventos globales de conexión
window.addEventListener('online', actualizarEstadoRed);
window.addEventListener('offline', actualizarEstadoRed);

// 2. Verificación y Preparación de Service Worker
const divSoporteSW = document.getElementById('soporte-sw');

if ('serviceWorker' in navigator) {
  divSoporteSW.textContent = '✅ Service Worker es soportado en este entorno.';
  divSoporteSW.classList.add('success');
  
  // El registro formal del Service Worker se implementará en la Semana 3
  console.log('Entorno listo para recibir service-worker.js');
} else {
  divSoporteSW.textContent = '❌ Service Worker NO es soportado en este navegador.';
  divSoporteSW.classList.add('error');
}

// Inicializar
actualizarEstadoRed();
```

### `styles.css`

```css
body {
  font-family: Arial, sans-serif;
  background-color: #f4f6f7;
  padding: 20px;
}

.container {
  max-width: 500px;
  margin: 0 auto;
  background: white;
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}

.status-box {
  padding: 12px;
  margin: 10px 0;
  border-radius: 4px;
  font-weight: bold;
}

.online { background-color: #d4edda; color: #155724; }
.offline { background-color: #f8d7da; color: #721c24; }
.success { border-left: 5px solid #28a745; }
.error { border-left: 5px solid #dc3545; }
```

## 3. Preguntas de Razonamiento Socrático (Anti-IA)

> **Pregunta:** "En el archivo manifest.json, asignamos "start_url": "./index.html". Si un usuario entra a la web desde la ruta http://localhost:8080/seccion/contacto.html y presiona el botón 'Instalar Aplicación', ¿qué página se abrirá cuando ejecute la app instalada desde su escritorio?"

**Respuesta Esperada:** Se abrirá index.html (la raíz definida en start_url), independientemente de cuál página específica estaba visitando en el navegador al momento de presionar el botón de instalación.

> **Pregunta:** "Si omito la etiqueta `<meta name="viewport" content="width=device-width, initial-scale=1.0">` en el archivo index.html, ¿afecta esto la evaluación de instalabilidad de la PWA en Lighthouse aunque el archivo manifest.json esté perfecto?"

**Respuesta Esperada:** Sí. Un requisito indispensable de una PWA es ser responsiva y adaptarse al lienzo del dispositivo. Sin la etiqueta de viewport, el navegador asume un ancho de escritorio fijo de 980px y Lighthouse marcará la aplicación como no optimizada para dispositivos móviles, bloqueando la auditoría PWA.

## 4. Hoja de Referencia (Cheat Sheet) para el Estudiante

| Propiedad / Archivo | Función Principal |
| --- | --- |
| `<link rel="manifest" href="manifest.json">` | Etiqueta HTML obligatoria en el `<head>` para vincular el manifiesto. |
| `"display": "standalone"` | Oculta la barra de direcciones e interfaz del navegador en la PWA instalada. |
| `"theme_color": "#hex"` | Pinta la barra superior del sistema operativo del color especificado. |
| `window.addEventListener('offline', fn)` | Captura el instante exacto en que el dispositivo pierde la conexión a red. |
| `navigator.onLine` | Propiedad booleana (true/false) que retorna el estado actual de red del cliente. |
