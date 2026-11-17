if ('serviceWorker' in navigator) {
  navigator.serviceWorker.addEventListener('message', (event) => {
    if (event.data && event.data.tipo === 'OUTBOX_SINCRONIZADO') {
      console.log('[UI] Confirmación recibida del Service Worker. Actualizando bandeja...');
      renderizarColaOutbox();
    }
  });
}

function procesarEnvioReporte(datosFormulario){
  const endpoint = 'https://jsonplaceholder.typicode.com/posts';

  return fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(datosFormulario)
  })
    .then((respuesta) => {
      if (!respuesta.ok) throw new Error('Error HTTP del servidor');
      return respuesta.json();
    })
    .then(() => {
      // Envío exitoso en vivo: registrar en bitácora local como sincronizado
      return guardarRegistro({
        ...datosFormulario,
        estado: 'sincronizado',
        fechaCreacion: Date.now()
      });
    })
    .catch(() => {
      console.warn('[Outbox] Sin conexión. Encolando transacción localmente...');
      // Falla de red: guardar en IndexedDB como pendiente para reenvío posterior
      return guardarRegistro({
        ...datosFormulario,
        estado: 'pendiente',
        fechaCreacion: Date.now()
      })
        .then(() => {
          // Detección de soporte para Background Sync API
          if ('serviceWorker' in navigator && 'SyncManager' in window) {
            return navigator.serviceWorker.ready
              .then((registro) => {
                console.log('[Outbox] Registrando etiqueta sync-reportes en el SW...');
                return registro.sync.register('sync-reportes');
              });
          }
        });
    })
    .then(() => {
      // Actualizar la lista visual en ambos escenarios
      return renderizarColaOutbox();
    });
}

function sincronizarPendientesFallback(){
  console.log('[Outbox] Conexión detectada. Buscando registros pendientes...');

  return obtenerTodosLosRegistros()
    .then((registros) => {
      const pendientes = registros.filter((item) => item.estado === 'pendiente');

      if (pendientes.length === 0) {
        console.log('[Outbox] No hay transacciones pendientes por sincronizar.');
        return;
      }

      // Convertir cada registro pendiente en una promesa de envío + actualización
      const promesasDeEnvio = pendientes.map((item) => {
        return fetch('https://jsonplaceholder.typicode.com/posts', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ title: item.titulo, body: item.descripcion })
        })
          .then((res) => {
            if (!res.ok) throw new Error('Falla al reintentar envío');
            // Actualizar estado en IndexedDB de 'pendiente' a 'sincronizado'
            return actualizarEstadoRegistro(item.id, 'sincronizado');
          });
      });

      // Esperar a que todos los reenvíos concluyan
      return Promise.all(promesasDeEnvio);
    })
    .then(() => {
      return renderizarColaOutbox();
    })
    .catch((error) => {
      console.error('[Outbox] Error durante la sincronización masiva:', error);
    });
}

// Escuchar el regreso de la conectividad
window.addEventListener('online', () => {
  actualizarIndicadorRed();
  // Degradación elegante: Solo sincronizar desde UI si el navegador NO soporta Background Sync (ej. Safari/iOS)
  if (!('SyncManager' in window)) {
    console.log('[Outbox] Navegador sin SyncManager. Ejecutando fallback por evento online...');
    sincronizarPendientesFallback();
  }
});

window.addEventListener('offline', actualizarIndicadorRed);
// READ: recuperar y mostrar la bandeja guardada en IndexedDB.
function renderizarColaOutbox(){
  return obtenerTodosLosRegistros().then((registros) => {
    const lista = document.getElementById('lista-outbox');
    lista.textContent = '';

    registros.forEach((registro) => {
      const item = document.createElement('li');
      item.textContent = registro.titulo + ' — ' + registro.estado + ' — ' +
        new Date(registro.fechaCreacion).toLocaleString('es-MX');
      lista.appendChild(item);
    });
  });
}

function actualizarIndicadorRed(){
  const indicador = document.getElementById('badge-red');
  indicador.textContent = navigator.onLine ? 'En Línea' : 'Sin conexión';
  indicador.className = 'badge ' + (navigator.onLine ? 'online' : 'offline');
}

// Conectar el formulario con el envío resiliente proporcionado.
document.getElementById('form-incidencia').addEventListener('submit', (e) => {
  e.preventDefault();
  const formulario = e.currentTarget;
  const datosFormulario = {
    titulo: document.getElementById('titulo').value,
    descripcion: document.getElementById('descripcion').value
  };

  procesarEnvioReporte(datosFormulario)
    .then(() => formulario.reset())
    .catch((error) => console.error('[Outbox] Error al guardar el reporte:', error));
});

// DELETE: eliminar únicamente los registros sincronizados.
document.getElementById('btn-purgar').addEventListener('click', () => {
  obtenerTodosLosRegistros()
    .then((registros) => {
      const sincronizados = registros.filter((item) => item.estado === 'sincronizado');
      return Promise.all(sincronizados.map((item) => eliminarRegistro(item.id)));
    })
    .then(() => renderizarColaOutbox())
    .catch((error) => console.error('[Outbox] Error al purgar los registros:', error));
});

// Recuperar la cola al abrir la página, también sin conexión.
actualizarIndicadorRed();
renderizarColaOutbox()
  .catch((error) => console.error('[Outbox] Error al leer la bandeja:', error));

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('./sw.js')
    .catch((error) => console.error('[SW] Error al registrar el Service Worker:', error));
}
