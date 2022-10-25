window.onload = function () {
    const mkScript = document.createElement('script');
    mkScript.src = "https://js-cdn.music.apple.com/musickit/v3/musickit.js";
    mkScript.setAttribute('data-web-component', undefined);
    mkScript.setAttribute('async', undefined);
    document.head.appendChild(mkScript);
}

export {};