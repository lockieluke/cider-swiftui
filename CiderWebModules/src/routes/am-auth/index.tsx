/// <reference types="musickit-typescript" />
/* @refresh reload */

import {Spinner, SpinnerType} from "solid-spinner";
import {render, Show} from "solid-js/web";
import "@src/index.scss";
import {IS_DEV} from "@src/lib/dev.ts";
import {MetaProvider, Title} from "@solidjs/meta";
import {createEffect, createSignal} from "solid-js";
import to from "await-to-js";
import {clsx} from "clsx";

declare const AM_TOKEN: string;

const urlSearchParams = new URLSearchParams(location.search);

const App = () => {
    const [readyToRedirect, setReadyToRedirect] = createSignal(false);
    const [manualSignin, setManualSignin] = createSignal(false);

    const loadMKJSScripts = () => {
        const mkScript = document.createElement("script");
        mkScript.src = "https://js-cdn.music.apple.com/musickit/v3/musickit.js";
        mkScript.toggleAttribute("data-web-component");
        mkScript.toggleAttribute("async");
        document.head.appendChild(mkScript);
    };

    const authorize = async () => {
        const mk = MusicKit.getInstance();

        const [aErr, userToken] = await to(mk.authorize());
        if (aErr) {
            window.webkit.messageHandlers.ciderkit.postMessage({
                event: "error",
                message: `Failed to authenticate user: ${aErr.message}`
            });
            console.error(`Failed to authenticate user: ${aErr.message}`);
            return;
        }

        if (userToken) {
            window.webkit.messageHandlers.ciderkit.postMessage({
                event: "authenticated",
                token: userToken
            });
        }
    };

    createEffect(() => {
        setManualSignin(urlSearchParams.has("manual-signin"));

        document.addEventListener("musickitloaded", async () => {
            console.log(`MusicKit ${MusicKit.version} loaded`);
            try {
                await MusicKit.configure({
                    developerToken: AM_TOKEN,
                    app: {
                        name: "Apple Music",
                        build: "1978.4.1",
                        version: "1.0"
                    }
                });
            } catch (err) {
                const error = err as Error;
                window.webkit.messageHandlers.ciderkit.postMessage({
                    event: "error",
                    message: `Failed to configure MusicKit: ${error.message}`
                });
                return;
            }

            const mk = MusicKit.getInstance();

            if (urlSearchParams.has("signout")) {
                await mk.unauthorize();
                localStorage.clear();
                window.webkit.messageHandlers.ciderkit.postMessage({
                    event: "signout-complete"
                });
                return;
            }

            if (mk.isAuthorized && mk.musicUserToken) {
                console.log("User was previously authorised");
                window.webkit.messageHandlers.ciderkit.postMessage({
                    event: "authenticated",
                    token: mk.musicUserToken
                });
                return;
            }

            if (manualSignin()) return;

            await authorize();

            setReadyToRedirect(true);
        });
        loadMKJSScripts();
    }, []);

    return (
        <MetaProvider>
            <Title>Apple Music Auth</Title>
            <div class={"flex flex-col space-y-5 h-screen items-center justify-center"} {...IS_DEV ? {} : {onContextMenu: e => e.preventDefault()}}>
                <Show when={!manualSignin()}>
                    <Spinner type={SpinnerType.tailSpin} />
                </Show>
                <h1 class={clsx({
                    "text-2xl font-bold": manualSignin()
                })}>{manualSignin() ? "You're signed out" : (readyToRedirect() ? "Authenticating" : "Waiting for Apple Music")}</h1>
                <Show when={manualSignin()}>
                    <button onClick={authorize} class={"cursor-default bg-red-500 hover:bg-red-400 transition-colors p-2 rounded-lg text-white font-medium"}>Sign Back In</button>
                </Show>
            </div>
        </MetaProvider>
    );
};

render(App, document.getElementById("app")!);
