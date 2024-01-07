import to from "await-to-js";
import store from "store2";
import * as _ from "lodash-es";

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
            setQueue: (opts: MusicKit.SetQueueOptions) => void,
            getQueue: () => MusicKit.MediaItem[],
            reorderQueue: (from: number, to: number) => void,
            previous: () => void,
            next: () => void,
            skipToQueueIndex: (index: number) => void,
            isAirPlayAvailable: () => boolean,
            openAirPlayPicker: () => void
        }
    }
}

type CiderMusicKitInstance = MusicKit.MusicKitInstance & {
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
        _reindex: () => void,
        nextPlayableItemIndex: number,
        previousPlayableItemIndex: number,
        position: number
    },
    queueIsEmpty: boolean,
    nowPlayingItem: MusicKit.MediaItem,
    currentPlaybackTime: number,
    currentPlaybackTimeRemaining: number,
    autoplayEnabled: boolean
};

const mkScript = document.createElement('script');
mkScript.src = "https://js-cdn.music.apple.com/musickit/v3/amp/musickit.js";
mkScript.toggleAttribute('data-web-component');
mkScript.toggleAttribute('async');
document.head.appendChild(mkScript);

document.addEventListener('musickitloaded', async function () {
    console.log(`MusicKit ${MusicKit.version} loaded`);

    const oldVersions = _.split(store.get('musickit.version-history'), '&');
    if (!store.has('musickit.version-history') || _.isNil(oldVersions.find(v => v.includes(MusicKit.version))) || oldVersions.findIndex(v => v.includes(MusicKit.version)) !== oldVersions.length - 1) {
        const versionHistory = store.get('musickit.version-history');
        store.set('musickit.version-history', `${_.isNil(versionHistory) ? "" : `${versionHistory}&`}${MusicKit.version}-${new Date().toUTCString()}`)
    }

    let [err, _mk] = await to<CiderMusicKitInstance>(MusicKit.configure({
        developerToken: AM_TOKEN,
        app: {
            name: "Apple Music",
            build: "1978.4.1",
            version: "1.0"
        }
    }) as Promise<CiderMusicKitInstance>);
    if (err || !_mk)
        return console.error(`Failed to configure MusicKit ${err}`);
    console.log(`MusicKit ${MusicKit.version} configured`);

    const mk = _mk as CiderMusicKitInstance;

    const storekit = mk._services.apiManager.store.storekit;
    storekit.userToken = AM_USER_TOKEN;
    storekit.userTokenIsValid = true;
    await mk.authorize();

    const updateNowPlayingInfo = () => {
        const nowPlayingItem = mk.nowPlayingItem;

        if (!_.isNil(nowPlayingItem)) {
            window.webkit.messageHandlers.ciderkit.postMessage({
                event: "mediaItemDidChange",
                id: nowPlayingItem.id,
                name: nowPlayingItem.attributes.name,
                artistName: nowPlayingItem.attributes.artistName,
                artworkURL: nowPlayingItem.attributes.artwork.url
            });
        }
    }

    let lastSyncedQueue: MusicKit.MediaItem[] = [];
    const syncQueue = (force: boolean = false) => {
        const ids = _.map(mk.queue.items, 'id');
        const lastSyncedIds = _.map(lastSyncedQueue, 'id');
        if (_.isEqual(ids, lastSyncedIds) && !force)
            return;

        lastSyncedQueue = window.ciderInterop.getQueue();
        window.webkit.messageHandlers.ciderkit.postMessage({
            event: "queueItemsDidChange",
            items: _.slice(lastSyncedQueue, mk.queue.position)
        });
    }

    // @ts-ignore
    mk.addEventListener('nowPlayingItemDidChange', () => {
        updateNowPlayingInfo();
        syncQueue(true);
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
        syncQueue();
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

    mk.addEventListener('mediaPlaybackError', (event: MusicKit.Events) => {
        console.error(`Error playing media: ${event}`);
    })

    mk.addEventListener('queueItemsDidChange', () => {
        syncQueue(true);
    })
    mk.addEventListener('queuePositionDidChange', () => {
        syncQueue();
    })
    // @ts-ignore
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
        setQueue: async opts => {
            const [err] = await to(mk.setQueue(opts));
            if (err) {
                console.error(`Failed to set queue ${err}`);
                return;
            }
        },
        getQueue: () => {
            return _.values(JSON.parse(JSON.stringify(mk.queue.items)));
        },
        reorderQueue: (from: number, to: number) => {
            const items = mk.queue._queueItems;
            const item = items[from];

            const newItems: [] = _.filter(items, (__, index) => _.toNumber(index) !== from) as [];
            newItems.splice(to, 0, item);

            mk.queue._queueItems = newItems;
            mk.queue._reindex();
        },
        previous: () => {
            if (!_.isEqual(mk.queue.previousPlayableItemIndex, -1) && !_.isNull(mk.queue.previousPlayableItemIndex))
                mk.skipToPreviousItem();
        },
        next: () => {
            if (!_.isEqual(mk.queue.nextPlayableItemIndex, -1) && !_.isNull(mk.queue.nextPlayableItemIndex))
                mk.skipToNextItem();
        },
        skipToQueueIndex: (index: number) => {
            // TODO: this doesn't work yet, need to figure out how to skip to a specific index in the queue
            mk.changeToMediaAtIndex(mk.queue.position + index);
        },
        isAirPlayAvailable: () => {
            // @ts-ignore
            const audioElement = mk._mediaItemPlayback._currentPlayer.audio;
            return !_.isNil(audioElement) && !_.isNil(audioElement.webkitShowPlaybackTargetPicker);
        },
        openAirPlayPicker: () => {
            if (window.ciderInterop.isAirPlayAvailable())
                // @ts-ignore
                mk._mediaItemPlayback._currentPlayer.audio.webkitShowPlaybackTargetPicker();
        }
    };
})

export {};
