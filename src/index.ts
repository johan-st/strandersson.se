// @ts-ignore - disregard elm type errors
import { Elm } from "./Main.elm";
import { getFeatureFlags, timedPromise, log, offlineFeatureFlags } from "./helpers";

// build time from environment variable
const buildTag = process.env.BUILD_TAG ? process.env.BUILD_TAG : "BUILD_TAG Not Set";
const nodeEnv = process.env.NODE_ENV ? process.env.NODE_ENV : "NODE_ENV Not Set";
let debug = false;

// GET FEATURE FLAGS (promise)
const ff = getFeatureFlags();
const timeout = timedPromise(2000);
const ffProm = Promise.race([ff, timeout])

if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
        ffProm.then(ff => {
            if (ff.flags.includes("serviceWorker")) {
                // register service worker
                navigator.serviceWorker
                    && navigator.serviceWorker.register(
                        new URL('sw.js', import.meta.url),
                        { scope: "/", type: "module" })
                        .then(registration => {
                            console.log("Service worker registered", registration);
                        })
            } else {
                // unregister service worker
                navigator.serviceWorker
                    && navigator.serviceWorker.getRegistrations()
                        .then(registrations => {
                            for (let registration of registrations) {
                                registration.unregister()
                                    .then(() => {
                                        console.log("Service worker unregistered", registration);
                                    })
                            }
                        })
            }
        })
    })
}


const init = (ff: FeatureFlags) => {
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
        featureFlags: ff,
    }
    // @ts-ignore - disregard elm type errors
    window.app = Elm.Main.init({
        node: document.querySelector("body"),
        flags: flags,
    });

    // Listen for commands from the `localStorageSet` port.
    // Turn the data to a string and put it in localStorage.
    // @ts-ignore - disregard elm type errors
    window.app.ports.localStorageSet.subscribe(function (fc) {
        localStorage.setItem('FoodCalculator', JSON.stringify(fc, null, 0))
    });
}


// wait for the feature flags to be loaded or timeout
// INIT ELM APP
ffProm
    .then(ff => { init(ff) }).
    catch(error => {
        console.log(error);
        init(offlineFeatureFlags);
    });


