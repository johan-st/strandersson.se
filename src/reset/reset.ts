// @ts-ignore - disregard elm type errors
if ("serviceWorker" in navigator) {
    // unregister service worker
    console.debug("unregistering service worker")
    navigator.serviceWorker
        && navigator.serviceWorker.getRegistrations()
            .then(registrations => {
                for (let registration of registrations) {
                    registration.unregister()
                        .then(() => {
                            console.debug("Service worker unregistered", registration);
                        })
                }
            })
}

location.assign("/")