import $ from "cash-dom";

declare const amToken: string;
declare const isForgettingAuth: boolean;

function sendNativeMessage(message: any) {
    alert(JSON.stringify(message));
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

$(function () {
    console.log(`CiderWebAuth is attached`);
    $('<script src="https://js-cdn.music.apple.com/musickit/v3/musickit.js" data-web-components async></script>').appendTo('head');

    document.addEventListener('musickitloaded', async function () {
        console.log(`MusicKit ${MusicKit.version} loaded`);
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
            sendNativeMessage({
                error: err,
                message: "Error initialising MusicKit"
            });
        }

        const currentURL = window.location.toString();
        const isInAuthorisationWindow = currentURL.includes('https://authorize.music.apple.com');
        const mk = MusicKit.getInstance();

        if (isInAuthorisationWindow) {
            enum AuthorisationWindowType {
                Continue = 'https://authorize.music.apple.com/?liteSessionId=',
                AppleIDSignIn = 'https://authorize.music.apple.com/woa'
            }

            console.log("In Authorisation Page");

            if (currentURL.includes(AuthorisationWindowType.AppleIDSignIn)) {
                sendNativeMessage({
                    action: 'authenticating-apple-id'
                });
            } else if (currentURL.includes(AuthorisationWindowType.Continue)) {
                sendNativeMessage({
                    action: 'authenticating-am'
                });

                const continueButton = await waitForDom('#app > div > div > section > div.base-content-wrapper__button-container > button') as HTMLButtonElement;
                continueButton.click();
            }
        } else {
            console.log("In Mock-Origin Page");
            if (isForgettingAuth && mk.isAuthorized) {
                console.log("Forgetting user authentication");
                await mk.unauthorize();
            }

            if (mk.isAuthorized) {
                console.log("User was already authenticated previously");
                sendNativeMessage({
                    action: 'authenticated',
                    token: mk.musicUserToken
                });
            } else {
                console.log("Restarting user authentication flow");
                let userToken: string;
                try {
                    userToken = await mk.authorize();
                } catch (err) {
                    sendNativeMessage({
                        error: err,
                        message: "Failed to authenticate user"
                    });
                } finally {
                    if (userToken)
                        sendNativeMessage({
                            action: 'authenticated',
                            token: userToken
                        });
                }
            }
        }
    })
})