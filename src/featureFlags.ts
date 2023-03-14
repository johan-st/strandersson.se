type FeatureFlags = {
    version: number;
    flags: string[];
};

/**
 * NOTE: These flags must match the keys in the featureFlags.json file. Keep these up to date.
 */
const flag = {
    sw: "serviceWorker",
    verbose: "verbose"
}

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

export { getFeatureFlags, offlineFeatureFlags, flag, FeatureFlags }