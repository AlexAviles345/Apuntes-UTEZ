# Tema 2.3 - Chrome DevTools como Centro de Mando PWA

## Guía de la fuente

> El texto describe a Chrome DevTools como el centro de mando esencial para examinar, depurar y evaluar aplicaciones web progresivas bajo circunstancias técnicas rigurosas. Explica que la pestaña de Application permite supervisar componentes vitales como los archivos de configuración, el ciclo de vida de los Service Workers y la retención de datos locales en bases de datos o memorias caché. Asimismo, detalla la utilidad de manipular el panel de Network para simular escenarios de conectividad adversos o conexiones lentas, garantizando que el software responda adecuadamente sin internet. Finalmente, destaca la incorporación de Lighthouse para realizar auditorías automáticas, una herramienta clave para verificar que el desarrollo cumple con los estándares modernos de calidad y accesibilidad móvil.

---

**Duración estimada:** 20 a 25 minutos (Teoría y Demostración Guiada)

**Objetivo de Aprendizaje:** Inspeccionar, depurar y auditar los componentes de una PWA utilizando las herramientas de desarrollador de Google Chrome, simulando escenarios extremos de red y almacenamiento local.

## 1. Desarrollos Conceptuales y Guión de Exposición

### A. La Pestaña Application (Aplicación)

**Es el panel neurálgico para cualquier desarrollador PWA. Se divide en tres bloques fundamentales:**

#### Application (Manifiesto y Service Workers):

- **Manifest:** Muestra la interpretación que hace el navegador del archivo manifest.json. Permite verificar la carga de íconos, colores de tema (theme_color), nombre, origen de arranque (start_url) y errores de sintaxis. Incluye la opción para forzar la instalación manual (Add to home screen).
- **Service Workers:** Estado de ciclo de vida del Service Worker (instalando, activado, en espera).

##### Casillas de control críticas:

- **Update on reload:** Fuerza la actualización del Service Worker al recargar la pestaña (imprescindible en desarrollo).
- **Bypass for network:** Desactiva temporalmente el Service Worker para que todas las peticiones vayan directo a internet.
- **Offline:** Simula desconexión a nivel de Service Worker.

```text
DevTools -> Application Panel
├── Application
│   ├── Manifest (Inspección de metadata e íconos)
│   └── Service Workers (Estado, Update on reload, Unregister)
├── Storage
│   ├── Storage quota (Uso en MB / Límite disponible)
│   ├── Local Storage / Session Storage
│   ├── IndexedDB (Base de datos NoSQL local)
│   └── Cache Storage (Archivos estáticos cacheados)
```

#### Storage (Almacenamiento Local):

Visualización gráfica de la cuota consumida contra el total disponible en el disco.

- **Cache Storage:** Inspección renglón por renglón de los archivos interceptados y guardados en memoria por la Cache API.
- **IndexedDB:** Árbol de base de datos relacional/NoSQL en el navegador donde se visualizan llaves y objetos guardados.
- **Botón "Clear site data":** Limpia de un solo clic la memoria caché, Service Workers registrados, cookies e IndexedDB para reiniciar el entorno de pruebas desde cero.

### B. La Pestaña Network (Red) y Simulación de Latencia

Una PWA debe probarse en condiciones de conectividad hostiles, no bajo la red de fibra óptica del laboratorio.

- **Throttling (Estrangulamiento de Red):** Menú desplegable para cambiar la velocidad de conexión en tiempo real:
- **Online:** Conexión sin restricciones.
- **Fast 3G / Slow 3G:** Simula latencia alta (400ms - 2000ms) y tasa de transferencia reducida.
- **Offline:** Desconecta virtualmente el navegador de la red para comprobar la tolerancia a fallos.
- **Disable Cache:** Casilla que deshabilita la caché HTTP convencional del navegador para forzar la descarga fresca de recursos durante el desarrollo.

### C. Auditoría Automática con Lighthouse

Lighthouse es un motor de auditoría automatizado integrado en DevTools que evalúa una aplicación bajo 5 métricas: Performance, Accessibility, Best Practices, SEO y PWA.

#### Criterios de Inspección PWA en Lighthouse:

- Servido bajo un contexto seguro (HTTPS/localhost).
- Registro de Service Worker válido.
- Respuesta exitosa HTTP 200 al navegar en modo Offline.
- **Manifiesto configurado con íconos de al menos 512x512 px y display:** standalone.
- Redirección exitosa de HTTP a HTTPS.

## 2. Demostración Práctica en Vivo (Live Coding / GUI)

- Abre cualquier PWA comercial en Chrome (ej. twitter.com o mobile.twitter.com).
- **Presiona F12 y dirígete a la pestaña Application:**
- Muestra el Service Worker activo y sus eventos registrados.
- Abre Cache Storage y despliega los archivos .js, .css e imágenes en caché.
- **Cambia a la pestaña Network:**
- Selecciona el modo Offline.
- Recarga la página y demuestra cómo la aplicación sigue renderizando la interfaz base gracias al Service Worker, en lugar de mostrar la pantalla de error de Chrome ("Sin conexión a internet").
- **Dirígete a la pestaña Lighthouse:**
- Selecciona el modo "Navigation" y dispositivo "Mobile".
- Ejecuta la auditoría y analiza junto con los alumnos el reporte de cumplimiento de los estándares PWA.

## 3. Preguntas de Razonamiento Socrático (Anti-IA)

> **Pregunta:** "Si modifiqué el código de mi archivo app.js en VS Code y recargué la página en Chrome, pero la consola sigue mostrando la versión vieja del script, ¿qué está pasando en DevTools y cómo lo soluciono sin borrar todo el proyecto?"

**Respuesta Esperada:** El Service Worker en segundo plano o la caché HTTP del navegador está sirviendo la versión previa guardada en memoria.

- **Solución en DevTools:** En la pestaña Application -> Service Workers, marcar la casilla "Update on reload", o bien ir a la pestaña Network y marcar "Disable cache" mientras DevTools esté abierto.

> **Pregunta:** "En la pestaña Application -> Storage, presiono el botón 'Clear site data'. ¿Esto desinstala la PWA del sistema operativo del usuario?"

**Respuesta Esperada:** No. Elimina los datos almacenados (IndexedDB, Cache Storage, LocalStorage) y desregistra el Service Worker, pero el acceso directo o el contenedor instalado en el sistema operativo permanece hasta que el usuario lo desinstale explícitamente desde la interfaz del sistema.

## 4. Hoja de Referencia (Cheat Sheet) para el Estudiante

| Sección en DevTools | Ruta de Acceso | Utilidad Principal |
| --- | --- | --- |
| Estado del Service Worker | Application -> Service Workers | Verificar estado, forzar actualización o desregistrar. |
| Inspección de Caché | Application -> Cache Storage | Ver qué recursos estáticos están guardados localmente. |
| Base de Datos Local | Application -> IndexedDB | Consultar registros y tablas guardadas en modo offline. |
| Simulador de Desconexión | Network -> Dropdown Online/Offline | Probar el comportamiento de la app sin red celular/Wi-Fi. |
| Limpieza Total de Estado | Application -> Storage -> Clear site data | Restablecer la app a su estado de fábrica en desarrollo. |
