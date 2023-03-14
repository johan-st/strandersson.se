import { manifest, version } from '@parcel/service-worker';

const cacheSalt = ""; // Change value to force update

const saltedVersion = `${version}${cacheSalt}`;

async function install() {
	console.log("installing", saltedVersion);
	console.log("manifest", manifest);

	const cache = await caches.open(saltedVersion);
	await cache.addAll(manifest);
}

async function activate() {
	console.log("activating", saltedVersion);

	const keys = await caches.keys();
	console.log("keys", keys);

	await Promise.all(
		keys.map(key => key !== saltedVersion && caches.delete(key))
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

