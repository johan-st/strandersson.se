import { rejects } from "assert";

/**
 * @example
 * { 
 *  "version": 1, 
 *  "flags": [ "serviceWorker", "debug" ] 
 * }
*/
const getFeatureFlags = (): Promise<FeatureFlags> => {
    return new Promise((resolve, _) => {
        fetch("/featureFlags.json")
            .then(resp => resp.json())
            .then(data => { resolve(data) })
    })
}

/**
 * Default feature flags to use if the server is down or client is offline
 */
const offlineFeatureFlags = {
    "version": 0,
    "flags": [
        "debug",
        "serviceWorker"
    ]
}

/**
 * Never resolves butcan reject with an error. Use to race against a promise that needs a timeout.
 * @param {number} timeout (in ms) 
 */
const timedPromise = (timeout: number): Promise<never> => {
    return new Promise((_, reject) => {
        setTimeout(() => {
            reject(new Error("Timed out in " + timeout + "ms."));
        }, timeout);
    });
}
/**
 * Log to console if shouldPrint is true
 * @param {boolean} shouldPrint
 * @param  {...any} args
 */
const log = (shouldPrint: boolean, ...args: any) => {
    if (shouldPrint) {
        console.log(...args);
    }
}

export { timedPromise, getFeatureFlags, log, offlineFeatureFlags }