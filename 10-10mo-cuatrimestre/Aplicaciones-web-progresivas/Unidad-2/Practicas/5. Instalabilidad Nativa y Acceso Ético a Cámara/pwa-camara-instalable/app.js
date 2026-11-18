// ---------- Service Worker ----------
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('./sw.js')
    .then((registro) => {
      console.log('SW registrado, scope:', registro.scope);
    })
    .catch((error) => {
      console.error('Error al registrar el SW:', error);
    });
}

// ---------- Instalación (Android / Chrome) ----------
let eventoInstalacionDiferido = null;
const btnInstalar = document.getElementById('btn-instalar');

window.addEventListener('beforeinstallprompt', (event) => {
  // Evita que el mini-banner automático aparezca antes de tiempo
  event.preventDefault();
  eventoInstalacionDiferido = event;
  btnInstalar.hidden = false;
});

btnInstalar.addEventListener('click', () => {
  if (!eventoInstalacionDiferido) return;

  eventoInstalacionDiferido.prompt();
  eventoInstalacionDiferido.userChoice
    .then((resultado) => {
      console.log('Resultado de instalación:', resultado.outcome);
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

window.addEventListener('appinstalled', () => {
  btnInstalar.hidden = true;
});

// ---------- iOS: guía de instalación manual ----------
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

// ---------- Cámara ----------
const visorVideo = document.getElementById('visor-camara');
const mensajeEstado = document.getElementById('estado');

let streamActual = null;
let modoCamaraActual = 'environment'; // 'environment' = trasera | 'user' = frontal

function actualizarMensajeEstado(texto) {
  mensajeEstado.textContent = texto;
}

function detenerCamaraActiva() {
  if (streamActual) {
    streamActual.getTracks().forEach((track) => {
      track.stop();
    });
    streamActual = null;
  }
}

function iniciarCamara(modo) {
  // CRÍTICO (iOS/Android): liberar el sensor antes de pedir otro
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

      // play() devuelve una promesa; se maneja sin async/await
      const reproduccion = visorVideo.play();
      if (reproduccion && typeof reproduccion.catch === 'function') {
        reproduccion.catch((error) => {
          console.warn('play() fue bloqueado:', error);
        });
      }

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

// Pre-Permiso, paso 1: solo se muestra el aviso explicativo
document.getElementById('btn-preparar-camara').addEventListener('click', () => {
  document.getElementById('aviso-permiso').hidden = false;
});

// Pre-Permiso, paso 2: el usuario consiente y recién entonces se toca el hardware
document.getElementById('btn-confirmar-permiso').addEventListener('click', () => {
  document.getElementById('aviso-permiso').hidden = true;
  iniciarCamara(modoCamaraActual);
});

// Alternar lente trasera <-> frontal
document.getElementById('btn-alternar-camara').addEventListener('click', () => {
  if (!streamActual) {
    actualizarMensajeEstado('Primero enciende la cámara con "Solicitar Acceso a Cámara".');
    return;
  }
  modoCamaraActual = (modoCamaraActual === 'environment') ? 'user' : 'environment';
  iniciarCamara(modoCamaraActual);
});

// Apagar cámara
document.getElementById('btn-apagar-camara').addEventListener('click', () => {
  detenerCamaraActiva();
  visorVideo.srcObject = null;
  actualizarMensajeEstado('Cámara apagada.');
});