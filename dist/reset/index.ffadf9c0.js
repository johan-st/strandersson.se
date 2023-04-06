"serviceWorker"in navigator&&(console.debug("unregistering service worker"),navigator.serviceWorker&&navigator.serviceWorker.getRegistrations().then((e=>{for(let r of e)r.unregister().then((()=>{console.debug("Service worker unregistered",r)}))}))),location.assign("/");
//# sourceMappingURL=index.ffadf9c0.js.map
