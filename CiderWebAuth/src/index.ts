import to from "await-to-js";

declare const amToken: string;
declare const initialURL: string;

declare global {
    interface Window {
        unauthoriseAM: () => void;
        importMusicKit: () => void;
        configureMusicKit: () => Promise<void>;
        sendNativeMessage: (message) => void;
    }
}

enum AuthorisationWindowType {
    Continue = 'https://authorize.music.apple.com/?liteSessionId=',
    AppleIDSignIn = 'https://authorize.music.apple.com/woa'
}

function waitForDom(selector: string): Promise<Element> {
    return new Promise(resolve => {
        if (document.querySelector(selector))
            resolve(document.querySelector(selector));

        const observer = new MutationObserver(() => {
            const dom = document.querySelector(selector);
            if (dom) {
                resolve(dom);
                observer.disconnect();
            }
        })

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    })
}

window.sendNativeMessage = (message) => {
    alert(JSON.stringify(message));
}

window.importMusicKit = () => {
    const mkScript = document.createElement('script');
    mkScript.src = "https://js-cdn.music.apple.com/musickit/v3/musickit.js";
    mkScript.setAttribute('data-web-component', undefined);
    mkScript.setAttribute('async', undefined);
    document.head.appendChild(mkScript);
}

window.configureMusicKit = () => {
    return new Promise<void>(async (resolve, reject) => {
        try {
            await MusicKit.configure({
                developerToken: amToken,
                app: {
                    name: "Apple Music",
                    build: "1978.4.1",
                    version: "1.0"
                }
            });
        } catch (err) {
            reject(err);
        } finally {
            resolve();
        }
    })
}

const currentURL = window.location.toString();
if (currentURL.includes(initialURL))
    window.importMusicKit();
else {
    if (currentURL.includes(AuthorisationWindowType.AppleIDSignIn)) {
        window.sendNativeMessage({
            action: 'authenticating-apple-id'
        });
    } else if (currentURL.includes(AuthorisationWindowType.Continue)) {
        window.sendNativeMessage({
            action: 'authenticating-am'
        });

        (async () => {
            const continueButton = await waitForDom('#app > div > div > section > div.base-content-wrapper__button-container > button') as HTMLButtonElement;
            continueButton.click();
        })();
    }

}

document.addEventListener('musickitloaded', async function () {
    console.log(`MusicKit ${MusicKit.version} loaded`);
    const [err] = await to(window.configureMusicKit());
    if (err) {
        window.sendNativeMessage({
            error: err,
            message: "Error initialising MusicKit"
        });
        return;
    }
    console.log(`MusicKit ${MusicKit.version} configured`);

    const mk = MusicKit.getInstance();

    if (mk.isAuthorized) {
        console.log("User was previously authorised");
        window.sendNativeMessage({
            action: 'authenticated',
            token: mk.musicUserToken
        });
        return;
    }

    const [aErr, userToken] = await to(mk.authorize());
    if (aErr) {
        window.sendNativeMessage({
            error: err,
            message: "Failed to authenticate user"
        });
        return;
    }

    if (userToken) {
        window.sendNativeMessage({
            action: 'authenticated',
            token: userToken
        });
    }
})

export {};