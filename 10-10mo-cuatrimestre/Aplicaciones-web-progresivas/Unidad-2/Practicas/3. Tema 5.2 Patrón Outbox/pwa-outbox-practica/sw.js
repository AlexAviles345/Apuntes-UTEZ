const CACHE_NAME = 'pwa-outbox-shell-v1';
const APP_SHELL = ['./', './index.html', './styles.css', './db-helper.js', './app.js', './manifest.json', './icon-192.png', './icon-512.png'];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
    .then(() => self.skipWaiting()));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(caches.keys().then((keys) => Promise.all(keys
    .filter((key) => key.startsWith('pwa-outbox-shell-') && key !== CACHE_NAME)
    .map((key) => caches.delete(key)))).then(() => self.clients.claim()));
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  // Las mutaciones POST siempre llegan a la red y su fallo lo maneja app.js.
  if (event.request.method !== 'GET' || url.origin !== self.location.origin) return;
  event.respondWith(caches.match(event.request).then((cached) => {
    if (cached) return cached;
    return fetch(event.request).catch((error) => {
      if (event.request.mode === 'navigate' && url.href.startsWith(self.registration.scope)) {
        return caches.match('./index.html');
      }
      throw error;
    });
  }));
});
