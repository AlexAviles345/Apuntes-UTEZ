// app.js - UI, pre-permiso y consumo de geo-helper.js

const UMBRAL_PRECISION_ALTA = 30; // metros

const $ = (id) => document.getElementById(id);

const btnAdjuntar = $('btn-adjuntar');
const btnConfirmar = $('btn-confirmar');
const btnCancelar = $('btn-cancelar');
const btnGuardarZona = $('btn-guardar-zona');

const cardPrePermiso = $('card-prepermiso');
const cardDenegado = $('card-denegado');
const cardManual = $('card-manual');
const cardResultado = $('card-resultado');

/* ---------- Helpers de UI ---------- */

function ocultarTodo() {
  cardPrePermiso.hidden = true;
  cardDenegado.hidden = true;
  cardManual.hidden = true;
  cardResultado.hidden = true;
  mostrarEstado('');
}

function mostrarEstado(texto, esError) {
  const p = $('estado');
  p.textContent = texto;
  p.classList.toggle('error', Boolean(esError));
}

function mostrarCargando(texto) {
  mostrarEstado(texto);
  btnAdjuntar.disabled = true;
  btnConfirmar.disabled = true;
}

function quitarCargando() {
  btnAdjuntar.disabled = false;
  btnConfirmar.disabled = false;
}

function mostrarMensajeError(mensaje) {
  mostrarEstado(mensaje, true);
}

function habilitarSelectorManualZona() {
  cardManual.hidden = false;
}

function renderizarResultadoUbicacion(ubicacion) {
  const esAlta = ubicacion.precisionMetros < UMBRAL_PRECISION_ALTA;
  const badge = $('badge-precision');

  badge.textContent = esAlta
    ? 'Precisión GPS Alta'
    : 'Ubicación Aproximada (Wi-Fi / IP)';
  badge.className = 'badge ' + (esAlta ? 'alta' : 'aprox');

  $('res-lat').textContent = ubicacion.latitud.toFixed(6);
  $('res-lon').textContent = ubicacion.longitud.toFixed(6);
  $('res-prec').textContent = '± ' + ubicacion.precisionMetros + ' m';
  $('res-fecha').textContent = new Date(ubicacion.timestamp).toLocaleString('es-MX');

  $('enlace-mapa').href =
    'https://www.openstreetmap.org/?mlat=' + ubicacion.latitud +
    '&mlon=' + ubicacion.longitud +
    '#map=17/' + ubicacion.latitud + '/' + ubicacion.longitud;

  cardResultado.hidden = false;
}

/* ---------- Lógica de ubicación ---------- */

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

/* ---------- Flujo de pre-permiso ---------- */

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

function manejarConfirmar() {
  // Llamada directa dentro del handler del clic (importante para Safari/iOS)
  solicitarUbicacion();
}

function manejarCancelar() {
  cardPrePermiso.hidden = true;
  habilitarSelectorManualZona();
}

function manejarGuardarZona() {
  const zona = $('select-zona').value;
  const direccion = $('input-direccion').value.trim();
  const salida = $('resultado-manual');

  if (!zona) {
    salida.textContent = 'Selecciona una zona primero.';
    salida.classList.add('error');
    return;
  }

  salida.classList.remove('error');
  salida.textContent = 'Zona guardada: ' + zona + (direccion ? ' · ' + direccion : '');
}

/* ---------- Eventos ---------- */

btnAdjuntar.addEventListener('click', manejarClickAdjuntar);
btnConfirmar.addEventListener('click', manejarConfirmar);
btnCancelar.addEventListener('click', manejarCancelar);
btnGuardarZona.addEventListener('click', manejarGuardarZona);

/* ---------- Service Worker ---------- */

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js')
      .then((reg) => console.log('[SW] Registrado, scope:', reg.scope))
      .catch((err) => console.error('[SW] Error al registrar:', err));
  });
}