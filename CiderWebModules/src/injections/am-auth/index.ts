/// <reference types="musickit-typescript" />

import authStyles from "./auth-styles.scss?inline";
import {waitForTheElement} from "wait-for-the-element";

declare global {
    interface Window {
        webkit: {
            messageHandlers: {
                ciderkit: {
                    postMessage: (message: object) => void
                }
            }
        }
    }
}

const entry = async () => {
    if (window.location.hostname === "idmsa.apple.com") {
        // inject auth styles
        const stylesheet = document.createElement("style");
        stylesheet.id = "auth-stylesheet";
        stylesheet.textContent = authStyles;
        document.head.appendChild(stylesheet);

        const iframe = await waitForTheElement("#aid-auth-widget-iFrame") as HTMLIFrameElement | null;
        (await waitForTheElement("#ac-globalfooter"))?.remove();

        // suppress crazy onresize errors
        document.body.onresize = null;

        console.log("Auth Script injected");
        if (iframe) {
            console.log("Auth iFrame found");
        }
    }

    if (location.hostname === "authorize.music.apple.com") {
        (await waitForTheElement("#app > div > div > footer"))?.remove();
        // const continueButton = await waitForTheElement("#app > div > div > section > div.base-content-wrapper__button-container > button");
        // if (continueButton) (<HTMLButtonElement>continueButton).click();

        const params = new URLSearchParams(location.search);
        window.webkit.messageHandlers.ciderkit.postMessage({
            event: "authenticated",
            token: params.get("musicUserToken")
        });
    }

    if (location.hostname === "localhost") {
        console.log("Running on localhost");
    }
};

if (location.hostname === "authorize.music.apple.com") {
    document.addEventListener("readystatechange", () => {
        if (document.readyState === "complete" || document.readyState === "interactive")
            document.body.style.backgroundColor = "transparent";
    });
}

if (document.readyState === "complete" || document.readyState === "interactive")
    entry();
else
    window.addEventListener("load", entry);

export {};
