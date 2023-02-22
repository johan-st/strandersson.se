import { Elm } from "./Main.elm";
// build time from environment variable
const buildTag = process.env.BUILD_TAG;
const nodeEnv = process.env.NODE_ENV;

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
    build
}
window.app = Elm.Main.init({
    node: document.querySelector("body"),
    flags: flags,
});

// Listen for commands from the `localStorageSet` port.
// Turn the data to a string and put it in localStorage.
window.app.ports.localStorageSet.subscribe(function (fc) {
    localStorage.setItem('FoodCalculator', JSON.stringify(fc));
});