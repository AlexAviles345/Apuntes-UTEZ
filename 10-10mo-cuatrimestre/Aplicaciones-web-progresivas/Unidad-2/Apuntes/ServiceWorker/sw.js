const CACHE_NAME = 'v1_cache_10A';

// self representa el contexto global del Service Worker (ServiceWorkerGlobalScope)
self.addEventListener('install', (event)=>{
    console.log('Service Worker instalado');
    
    event.waitUntil(
        caches.open(CACHE_NAME)
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


self.addEventListener('activate', (event)=>{
    console.log('Service Worker activado');
    event.waitUntil(
        caches.keys()
        .then((keys)=>{
            return Promise.all(
                keys.map(
                    (cacheName) => {
                        if(cacheName !== CACHE_NAME){
                            return caches.delete(cacheName);
                        }
                    }
                )
            )
        })
    );
});

self.addEventListener('fetch', (event)=>{
    console.log('Fetch', event.request.url);
    event.respondWith(
        caches.match(event.request) || fetch(event.request)
    )
});
