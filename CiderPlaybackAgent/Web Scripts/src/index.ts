import MusicKitInstance = MusicKit.MusicKitInstance;
import to from "await-to-js";
import {isEqual, map, values, filter} from "lodash";

declare let AM_TOKEN: string, AM_USER_TOKEN: string;

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
            setQueue: (mediaItem: MusicKit.SetQueueOptions) => void,
            getQueue: () => MusicKit.MediaItem[],
            reorderQueue: (from: number, to: number) => void
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
    queue: {
        items: MusicKit.MediaItem[],
        _queueItems: [],
        _reindex: () => void
    },
    queueIsEmpty: boolean,
    nowPlayingItem: MusicKit.MediaItem,
    currentPlaybackTime: number,
    currentPlaybackTimeRemaining: number,
    autoplayEnabled: boolean
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

    const updateNowPlayingInfo = () => {
        const nowPlayingItem = mk.nowPlayingItem;
        window.webkit.messageHandlers.ciderkit.postMessage({
            event: "mediaItemDidChange",
            id: nowPlayingItem.id,
            name: nowPlayingItem.attributes.name,
            artistName: nowPlayingItem.attributes.artistName,
            artworkURL: nowPlayingItem.attributes.artwork.url
        });
    }

    let lastSyncedQueue: MusicKit.MediaItem[] = [];
    const syncQueue = () => {
        const ids = map(mk.queue.items, 'id');
        const lastSyncedIds = map(lastSyncedQueue, 'id');
        if (isEqual(ids, lastSyncedIds))
            return;

        lastSyncedQueue = window.ciderInterop.getQueue();
        window.webkit.messageHandlers.ciderkit.postMessage({
            event: "queueItemsDidChange",
            items: lastSyncedQueue
        });
    }

    mk.addEventListener('mediaItemDidChange', () => {
        updateNowPlayingInfo();
    })

    mk.addEventListener('metadataDidChange', () => {
        updateNowPlayingInfo();
    })

    mk.addEventListener('playbackStateDidChange', () => {
        const state = MusicKit.PlaybackStates[mk.playbackState];
        window.webkit.messageHandlers.ciderkit.postMessage({
            event: "playbackStateDidChange",
            playbackState: state
        });
    })

    mk.addEventListener('playbackDurationDidChange', (event: { duration: number }) => {
        window.webkit.messageHandlers.ciderkit.postMessage({
            event: "playbackDurationDidChange",
            duration: event.duration
        });
    })

    mk.addEventListener('playbackTimeDidChange', () => {
        window.webkit.messageHandlers.ciderkit.postMessage({
            event: "playbackTimeDidChange",
            currentTime: mk.currentPlaybackTime,
            remainingTime: mk.currentPlaybackTimeRemaining
        });
    })

    mk.addEventListener('mediaPlaybackError', event => {
        console.error(`Error playing media: ${event}`);
    })

    mk.addEventListener('queueItemsDidChange', () => {
        syncQueue();
    })
    mk.addEventListener('queuePositionDidChange', () => {
        syncQueue();
    })
    mk.addEventListener('autoplayEnabledDidChange', () => {
        syncQueue();
    })

    window.ciderInterop = {
        mk,
        play: async () => {
            const [err] = await to(mk.play());
            if (err) {
                console.error(`Failed to initiate play ${err}`);
                return;
            }
        },
        setQueue: async mediaItem => {
            const [err] = await to(mk.setQueue(mediaItem));
            if (err) {
                console.error(`Failed to set queue ${err}`);
                return;
            }
        },
        getQueue: () => {
            return values(JSON.parse(JSON.stringify(mk.queue.items)));
        },
        reorderQueue: (from: number, to: number) => {
            const items = mk.queue._queueItems;
            const item = items[from];
            const newItems = filter(items, (_, index) => index !== from) as [];
            newItems.splice(to, 0, item);

            mk.queue._queueItems = newItems;
            mk.queue._reindex();
        }
    };
})

export {};
