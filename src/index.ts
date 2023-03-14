// @ts-ignore - disregard elm type errors
import { Elm } from "./Main.elm";
import { timedPromise, log } from "./helpers";
import { getFeatureFlags, offlineFeatureFlags, flag as f, FeatureFlags } from "./featureFlags";



// build time from environment variable
const buildTag = process.env.BUILD_TAG ? process.env.BUILD_TAG : "BUILD_TAG Not Set";
const nodeEnv = process.env.NODE_ENV ? process.env.NODE_ENV : "NODE_ENV Not Set";

// GET FEATURE FLAGS (promise)
const ff = getFeatureFlags();
const timeout = timedPromise(2000);
const ffProm = Promise.race([ff, timeout])

if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
        // register service worker
        console.debug("registering service worker")
        navigator.serviceWorker
            && navigator.serviceWorker.register(
                new URL('sw.js', import.meta.url),
                { scope: "/", type: "module" })
                .then(registration => {
                    console.debug("Service worker registered", registration);
                })
        // wait for the feature flags to be loaded or timeout
        ffProm.then(ff => {
            if (ff.flags.includes(f.sw)) {
            } else {
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
        })
    })
}


const init = (ff: FeatureFlags) => {
    if (ff.flags.includes(f.verbose)) {
        const verbose = true;
        log(verbose, "Debug mode enabled");
        log(verbose, `featureFlags (version: ${ff.version}): `, ff.flags);
        log(verbose, "Build tag:", buildTag);
        log(verbose, "Node env:", nodeEnv);
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
        console.warn("could not fetch live flags. Using offline defaults.")
        console.debug(error);
        init(offlineFeatureFlags);
    });


