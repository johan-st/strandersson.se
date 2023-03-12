
// const cache = "v20230312-3"; // Change value to force update
import { manifest, version } from '@parcel/service-worker';

async function install() {
	console.log("installing", version);
	console.log("manifest", manifest);

	const cache = await caches.open(version);
	await cache.addAll(manifest);
}

async function activate() {
	console.log("activating", version);

	const keys = await caches.keys();
	console.log("keys", keys);

	await Promise.all(
		keys.map(key => key !== version && caches.delete(key))
	);
}

addEventListener('install', e => e.waitUntil(install()));
addEventListener('activate', e => e.waitUntil(activate()));

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
			caches.open(cache).then(cache => {
				return cache.match(event.request).then(response => {
					return response || fetch(event.request).then(networkResponse => {
						cache.put(event.request, networkResponse.clone());
						return networkResponse;
					});
				})
			}))
	}
})

// // TODO: unregister service worker if feature flag is removed

// // unregister service worker
// if ("serviceWorker" in navigator) {
// 	window.addEventListener("load", () => {
// 		navigator.serviceWorker
// 			&& navigator.serviceWorker.getRegistrations()
// 				.then(registrations => {
// 					for (let registration of registrations) {
// 						registration.unregister()
// 					}
// 				})
// 	});
// }

