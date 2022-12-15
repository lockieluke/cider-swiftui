import MusicKitInstance = MusicKit.MusicKitInstance;
import to from "await-to-js";

declare let AM_TOKEN: string;
declare let AM_USER_TOKEN: string;

declare global {

    interface Window {
        webkit: {
            messageHandlers: {
                ciderkit: {
                    postMessage: (message: object) => void
                }
            }
        },
        ciderInterop: {
            mk: CiderMusicKitInstance,
            play: () => void,
            setQueue: (mediaItem: MusicKit.SetQueueOptions) => void
        }
    }
}

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
    },
    queue: [],
    queueIsEmpty: boolean,
    nowPlayingItem: MusicKit.MediaItem
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

    // Enable High Quality (256 kbps)
    (mk as any).bitrate = MusicKit.PlaybackBitrate.HIGH

    const updateNowPlayingInfo = () => {
        window.webkit.messageHandlers.ciderkit.postMessage({
            event: "mediaItemDidChange",
            name: mk.nowPlayingItem.title,
            artistName: mk.nowPlayingItem.artistName,
            artworkURL: mk.nowPlayingItem.artworkURL
        });
    }

    mk.addEventListener(MusicKit.Events.mediaItemDidChange, () => {
        updateNowPlayingInfo();
    })

    mk.addEventListener(MusicKit.Events.playbackStateDidChange, () => {
        const state = MusicKit.PlaybackStates[mk.playbackState];
        console.log(`Playback State changed ${state}`);
        window.webkit.messageHandlers.ciderkit.postMessage({
            event: "playbackStateDidChange",
            playbackState: state
        });
    })

    window.ciderInterop = {
        mk,
        play: async () => {
            const [err] = await to(mk.play());
            if (err) {
                console.error(`Failed to initiate play ${err}`);
                return;
            }

            console.log("Initiated play");
        },
        setQueue: async mediaItem => {
            const [err, setQueueResult] = await to(mk.setQueue(mediaItem));
            if (err) {
                console.error(`Failed to set queue ${err}`);
                return;
            }

            console.log(`Initiated setQueue with ${setQueueResult.length} items`);
        }
    };
})

export {};
