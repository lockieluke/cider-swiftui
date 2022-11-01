import MusicKitInstance = MusicKit.MusicKitInstance;

declare let AM_TOKEN: string;
declare let AM_USER_TOKEN: string;

type CiderMusicKitInstance = MusicKitInstance & {
    _services: {
        apiManager: {
            store: {
                storekit: {
                    userToken: string,
                    userTokenIsValid: boolean
                }
            }
        }
    }
};

const mkScript = document.createElement('script');
mkScript.src = "https://js-cdn.music.apple.com/musickit/v3/musickit.js";
mkScript.setAttribute('data-web-component', undefined);
mkScript.setAttribute('async', undefined);
document.head.appendChild(mkScript);

document.addEventListener('musickitloaded', async function () {
    console.log(`MusicKit ${MusicKit.version} loaded`);

    let mk: CiderMusicKitInstance;
    try {
        mk = await MusicKit.configure({
            developerToken: AM_TOKEN,
            app: {
                name: "Apple Music",
                build: "1978.4.1",
                version: "1.0"
            }
        }) as CiderMusicKitInstance;
    } catch (e) {
        console.error(e);
    }
    console.log(`MusicKit ${MusicKit.version} configured`);

    const storekit = mk._services.apiManager.store.storekit;
    storekit.userToken = AM_USER_TOKEN;
    storekit.userTokenIsValid = true;
    await mk.authorize();
})

export {};