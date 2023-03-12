import { Elm } from "./Main.elm";
import { getFeatureFlags, timedPromise, log } from "./helpers.js";

// build time from environment variable
const buildTag = process.env.BUILD_TAG;
const nodeEnv = process.env.NODE_ENV;
let debug = false;

// register service worker
if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
        navigator.serviceWorker
            && navigator.serviceWorker.register(
                new URL('./sw.js', import.meta.url),
                { scope: "/", type: "module" }
            )
    });
}

// unregister service worker
// if ("serviceWorker" in navigator) {
//     window.addEventListener("load", () => {
//         navigator.serviceWorker
//             && navigator.serviceWorker.getRegistrations()
//                 .then(registrations => {
//                     for (let registration of registrations) {
//                         registration.unregister()
//                     }
//                 })
//     });
// }





// INIT
const ff = getFeatureFlags();
const timeout = timedPromise(2000);
// wait for the feature flags to be loaded or timeout
Promise.race([ff, timeout])
    .then(ff => {
        // Set the feature flags on window so they can be accessed from the service worker (what is a better way?)
        if (ff.flags.includes("debug")) {
            debug = true;
            log(debug, "Debug mode enabled");
            log(debug, `featureFlags (version: ${ff.version}): `, ff.flags);
            log(debug, "Build tag:", buildTag);
            log(debug, "Node env:", nodeEnv);
        }

        // decide what tag to show in the footer
        let build = "";
        if (nodeEnv == "production") {
            build = buildTag
        } else {
            build = " <DEV>:" + buildTag
        }

        // Get the data from localStorage, if it exists.
        // put the data in the flags for the elm app.
        const storedData = localStorage.getItem('FoodCalculator');
        const flags = {
            foodCalculator: storedData ? JSON.parse(storedData) : null,
            build,
            // featureFlags: ff,
        }
        window.app = Elm.Main.init({
            node: document.querySelector("body"),
            flags: flags,
        });

        // Listen for commands from the `localStorageSet` port.
        // Turn the data to a string and put it in localStorage.
        window.app.ports.localStorageSet.subscribe(function (fc) {
            localStorage.setItem('FoodCalculator', JSON.stringify(fc, null, 0));
        });

    })
    .catch(error => {
        console.log(error);
    });


