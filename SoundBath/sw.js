// Offline cache so Ma works from the home screen without a connection.
const CACHE = "ma-v2";
const CORE = ["./", "index.html", "manifest.webmanifest", "icon.svg", "icon-180.png", "icon-512.png"];
self.addEventListener("install", e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE))); self.skipWaiting(); });
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))));
  self.clients.claim();
});
self.addEventListener("fetch", e => {
  if (e.request.method !== "GET") return;
  e.respondWith(caches.match(e.request).then(hit => hit || fetch(e.request).then(res => {
    const copy = res.clone();
    if (res.ok || res.type === "opaque") caches.open(CACHE).then(c => c.put(e.request, copy));
    return res;
  }).catch(() => caches.match("index.html"))));
});
