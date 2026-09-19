/* Кеш вимкнено. Цей service worker сам себе знімає й чистить старі кеші,
   щоб апка завжди бралася свіжою з мережі (жодних застарілих версій). */
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    try {
      const ks = await caches.keys();
      await Promise.all(ks.map((k) => caches.delete(k)));
    } catch (err) {}
    try { await self.registration.unregister(); } catch (err) {}
    try {
      const cs = await self.clients.matchAll({ type: 'window' });
      cs.forEach((c) => c.navigate(c.url));
    } catch (err) {}
  })());
});
