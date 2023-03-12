/**
 * Promise feature flags from the server.
 * Always resolves, even if there is an error
 * sets the window.featureFlags variable
 * @returns {Promise} feature-flags
 * @example
 * { 
 *  "version": 1, 
 *  "flags": [ "serviceWorker", "debug" ] 
 * }
*/
const getFeatureFlags = () => {
    return new Promise((resolve, _) => {
        fetch("/featureFlags.json")
            .then(resp => resp.json())
            .then(data => { resolve(data) })
            .catch(error => {
                console.log("Error loading feature flags", error);
                resolve(defaultFeatureFlags);
            });
    })
}

const defaultFeatureFlags = { "version": 0, "flags": ["serviceWorker"] }

/**
 * Never resolves, used to time out a promise
 * @param {int} timeout (in ms) 
 * @returns 
 */
const timedPromise = (timeout) => {
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
const log = (shouldPrint, ...args) => {
    if (shouldPrint) {
        console.log(...args);
    }
}

export { timedPromise, getFeatureFlags, log, defaultFeatureFlags }