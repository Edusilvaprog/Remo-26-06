const CACHE = 'vertice-gestao-v8';
const ASSETS = [
  './index.html',
  './vertice-gestao.webmanifest',
  './logo.png',
  './vertice-icon-96.png',
  './vertice-icon-192.png',
  './vertice-icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(ASSETS).catch(() => {}))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  const url = new URL(event.request.url);

  // Nunca cacheia ou intercepta requisições de APIs dinâmicas
  if (
    url.hostname.includes('supabase.co') || 
    url.hostname.includes('open-meteo.com') || 
    url.hostname.includes('api.cloudinary.com')
  ) {
    return; // Passa direto para a rede
  }

  event.respondWith(
    caches.match(event.request).then((cached) => {
      const fetchPromise = fetch(event.request)
        .then((response) => {
          if (response && response.status === 200 && event.request.url.startsWith('http')) {
            const contentType = response.headers.get('content-type') || '';
            const isJs = event.request.url.includes('.js') || contentType.includes('javascript');
            
            // Validação estrita para o CDN do Tailwind (evitar cachear portais cativos de Wi-Fi)
            if (event.request.url.includes('tailwindcss.com') && !isJs) {
              return response; 
            }

            const clone = response.clone();
            caches.open(CACHE).then((cache) => cache.put(event.request, clone));
          }
          return response;
        })
        .catch(() => cached);
        
      return cached || fetchPromise;
    })
  );
});
