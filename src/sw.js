
const cacheName = "v20230312-3"; // Change value to force update


// Register the service worker
self.addEventListener("install", event => {
	// Kick out the old service worker
	self.skipWaiting();

	event.waitUntil(
		caches.open(cacheName).then(cache => {
			return cache.addAll([
				"/",
				"favicon.ico", // Favicon, IE and fallback for other browsers
				"index.html", // Main HTML file
				"index.js", // Main Javascript file
				"manifest.json", // Manifest file
				"maskable_icon.png", // Favicon, maskable https://web.dev/maskable-icon
				"style.css", // Main CSS file
				"LivsmedelsDB.json", // Database of foodstuffs from Livsmedelsverket (Swedish Food Agency) 
			]).catch(error => {
				console.log("Error caching assets", error);
			});
		})
	);
});

self.addEventListener("activate", event => {
	// Delete any non-current cache
	event.waitUntil(
		caches.keys().then(keys => {
			Promise.all(
				keys.map(key => {
					if (![cacheName].includes(key)) {
						return caches.delete(key);
					}
				})
			)
		})
	);
});

// Offline-first, cache-first strategy (except for featureFlags.json)
// Kick off two asynchronous requests, one to the cache and one to the network
// If there's a cached version available, use it, but fetch an update for next time.
// Gets data on screen as quickly as possible, then updates once the network has returned the latest data. 
self.addEventListener("fetch", event => {
	// do not cache the featureFlags.json file
	// TODO: make this support api calls with no extension
	if (event.request.url.includes("featureFlags.json")) {
		console.log("featureFlags.json", event.request.url)
		fetch(event.request).then(networkResponse => {
			return networkResponse;
		})
	} else {
		event.respondWith(
			caches.open(cacheName).then(cache => {
				return cache.match(event.request).then(response => {
					return response || fetch(event.request).then(networkResponse => {
						cache.put(event.request, networkResponse.clone());
						return networkResponse;
					});
				})
			}))
	}
})

// TODO: unregister service worker if feature flag is removed