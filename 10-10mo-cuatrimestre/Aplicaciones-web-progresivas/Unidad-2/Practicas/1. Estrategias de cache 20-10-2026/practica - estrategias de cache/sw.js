
const CACHE_DYNAMIC = 'app-dynamic';
const CACHE_STATIC = 'app-static';

//Self contexto del hilo primario
self.addEventListener('install', (event)=>{
    console.log('Service Worker instalado');
    
    event.waitUntil(
        caches.open(CACHE_STATIC)
        .then((cacheCreado)=>{
            return cacheCreado.addAll(
                [
                    '/',
                    '/index.html',
                    '/styles.css',
                    '/script.js',
                    '/app.js'
                ]
            )
        })
    );
});


self.addEventListener('activate', (event)=>{
    console.log('Service Worker activado');
    event.waitUntil(
        caches.keys()
        .then((keys)=>{
            return Promise.all(
                keys.map(
                    (cacheName) => {
                        if(cacheName !== CACHE_STATIC && cacheName !== CACHE_DYNAMIC){
                            return caches.delete(cacheName);
                        }
                    }
                )
            )
        })
    );
});

self.addEventListener('fetch', (event) => {
    const request = event.request;

    const url = new URL(request.url);

    if (url.origin === 'https://fakestoreapi.com') {
        event.respondWith(networkFirst(request));
    } else {
        event.respondWith(cacheFirst(request));
    }
});


function cacheFirst(request) {
    return caches.match(request)
    .then((respCache)=>{
        if(respCache){
            return respCache;
        }
        return fetch(request)
        .then((respNetwork)=>{
            return caches.open(CACHE_STATIC)
            .then((cacheStatic)=>{
                cacheStatic.put(request, respNetwork.clone());
                return respNetwork;
            })
        })
    })
}

function networkFirst(request){
    return fetch(request)
    .then((respNetwor)=>{
        return caches.open(CACHE_DYNAMIC)
        .then((cacheDynamic)=>{
            cacheDynamic.put(request, respNetwor.clone());
            return respNetwor;
        })
    })
    .catch(()=>{
        return caches.match(request)
        .then((respCache)=>{
            if(respCache){
                return respCache;
            }
            return new Response(
                JSON.stringify({error: 'No hay red ni cache'}),
                {headers: { 'Content-Type': 'application/json' }}
            );
        })
    })
}
