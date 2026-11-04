const CACHE_STATIC_NAME = 'static-v2';
const CACHE_DYNAMIC_NAME = 'dynamic-v2';
const DYNAMIC_LIMIT = 5; // Límite máximo de elementos en caché dinámica
const TTL_MAX_SECONDS = 30; // Tiempo de vida máximo de 30 segundos para pruebas

self.addEventListener('activate', (event) => {
    const listaBlanca = [CACHE_STATIC_NAME, CACHE_DYNAMIC_NAME];

    event.waitUntil(
        caches.keys()
            .then((nombresCaches) => {
                return Promise.all(
                    nombresCaches.map((nombreCache) => {
                        if (!listaBlanca.includes(nombreCache)) {
                            console.log('[SW] Purgando contenedor obsoleto:', nombreCache);
                            return caches.delete(nombreCache);
                        }
                    })
                );
            })
            .then(() => self.clients.claim())
    );
});


// self representa el contexto global del Service Worker
self.addEventListener('install', (event)=>{
    console.log('Service Worker instalado');
    
    event.waitUntil(
        caches.open(CACHE_STATIC_NAME)
        .then((cacheCreado)=>{
            return cacheCreado.addAll(
                [
                    '/',
                    '/index.html',
                    '/styles.css',
                    '/app.js'
                ]
            )
        })
    );
});


self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);

    // Rutas estáticas locales
    if (url.origin === location.origin && !url.pathname.includes('/api/')) {
        event.respondWith(cacheFirstEvolucionado(event.request));
        return;
    }

    // Rutas a APIs dinámicas
    if (url.hostname.includes('dragonball-api.com')) {
        event.respondWith(networkFirstEvolucionado(event.request));
        return;
    }
});

function limpiarCacheLimitado(nombreCache, maxElementos) {
    return caches.open(nombreCache)
        .then((cache) => {
            return cache.keys()
                .then((keys) => {
                    if (keys.length > maxElementos) {
                        return cache.delete(keys[0])
                            .then(() => limpiarCacheLimitado(nombreCache, maxElementos));
                    }
                });
        });
}

function crearRespuestaConTimestamp(respuestaOriginal) {
    // 1. Copiar las cabeceras originales de la respuesta
    const nuevasCabeceras = new Headers(respuestaOriginal.headers);

    // 2. Inyectar nuestra cabecera personalizada con la fecha/hora actual
    nuevasCabeceras.append('x-sw-timestamp', Date.now().toString());

    // 3. Leer el cuerpo de la respuesta como Blob y reconstruir el objeto Response
    return respuestaOriginal.blob()
        .then((cuerpoBlob) => {
            return new Response(cuerpoBlob, {
                status: respuestaOriginal.status,
                statusText: respuestaOriginal.statusText,
                headers: nuevasCabeceras
            });
        });
}

function esRespuestaFresca(respuesta, maxSegundos) {
    if (!respuesta) return false;

    // Extraer nuestra cabecera personalizada
    const timestampGuardado = respuesta.headers.get('x-sw-timestamp');
    if (!timestampGuardado) return false; // Si no tiene el timestamp inyectado, se considera obsoleta

    const fechaGuardada = parseInt(timestampGuardado, 10);
    const fechaActual = Date.now();
    const diferenciaSegundos = (fechaActual - fechaGuardada) / 1000;

    console.log(`[SW] Edad del recurso inyectado: ${diferenciaSegundos.toFixed(1)}s (Máximo permitido: ${maxSegundos}s)`);

    return diferenciaSegundos < maxSegundos;
}

function cacheFirstEvolucionado(request) {
    return caches.match(request)
        .then((respuestaCache) => {
            // 1. Evaluar si existe en caché y si aún está fresca según el TTL inyectado
            if (respuestaCache && esRespuestaFresca(respuestaCache, TTL_MAX_SECONDS)) {
                return respuestaCache;
            }

            console.log('[SW] Recurso no disponible o expirado. Solicitando a la red:', request.url);

            // 2. Si falló la caché o expiró, salir a la red
            return fetch(request)
                .then((respuestaRed) => {
                    // Inyectar timestamp antes de almacenar en la Cache API
                    return crearRespuestaConTimestamp(respuestaRed)
                        .then((respuestaConTimestamp) => {
                            return caches.open(CACHE_STATIC_NAME)
                                .then((cache) => {
                                    cache.put(request, respuestaConTimestamp.clone());
                                    return respuestaConTimestamp;
                                });
                        });
                });
        });
}

function networkFirstEvolucionado(request) {
    return fetch(request)
        .then((respuestaRed) => {
            if (respuestaRed.status === 200) {
                // Transformar la respuesta inyectando el timestamp
                return crearRespuestaConTimestamp(respuestaRed)
                    .then((respuestaConTimestamp) => {
                        return caches.open(CACHE_DYNAMIC_NAME)
                            .then((cache) => {
                                cache.put(request, respuestaConTimestamp.clone());

                                // Aplicar restricción de tamaño en la caché dinámica
                                limpiarCacheLimitado(CACHE_DYNAMIC_NAME, DYNAMIC_LIMIT);

                                return respuestaConTimestamp;
                            });
                    });
            }

            return respuestaRed;
        })
        .catch(() => {
            console.warn('[SW] Falla de red. Verificando respaldo en caché con TTL inyectado...');

            return caches.match(request)
                .then((respuestaCache) => {
                    // Validar existencia Y frescura del timestamp inyectado
                    if (respuestaCache && esRespuestaFresca(respuestaCache, TTL_MAX_SECONDS)) {
                        return respuestaCache;
                    }

                    // Fallback si no hay red y los datos cacheados expiraron
                    return new Response(
                        JSON.stringify({
                            error: true,
                            mensaje: "La conexión falló y los datos locales han expirado o no existen."
                        }),
                        {
                            headers: { 'Content-Type': 'application/json' }
                        }
                    );
                });
        });
}
