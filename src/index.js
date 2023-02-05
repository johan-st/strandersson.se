import { Elm } from "./Main.elm";

// Get the data from localStorage, if it exists.
// put the data in the flags for the elm app.
const storedData = localStorage.getItem('FoodCalculator');
const flags = {
    foodCalculator: storedData ? JSON.parse(storedData) : null
}
window.app = Elm.Main.init({
    node: document.querySelector("body"),
    flags: flags
});

// Listen for commands from the `localStorageSet` port.
// Turn the data to a string and put it in localStorage.
window.app.ports.localStorageSet.subscribe(function (fc) {
    localStorage.setItem('FoodCalculator', JSON.stringify(fc));
});