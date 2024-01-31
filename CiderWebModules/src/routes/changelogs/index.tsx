import {render, Show} from "solid-js/web";
import {createEffect, createSignal} from "solid-js";
import * as _ from "lodash-es";
import {IS_DEV} from "@src/lib/dev.ts";
import {Spinner, SpinnerType} from "solid-spinner";
import {clsx} from "clsx";
import {TransitionGroup} from "solid-transition-group";
import matter from "gray-matter";
import {marked} from "marked";
import DOMPurify from "dompurify";

import "@src/index.scss";
import "./style.scss";

declare global {
    interface Window {
        setMarkdown: (markdown: string) => void;
        BUILD_INFO: {
            version: string;
            build: number;
        }
    }
}

type ChangelogsMetadata = {
    title: string;
    heroVideo?: string;
    heroImage?: string;
}

const App = () => {
    const [markdownInHtml, setMarkdownInHtml] = createSignal("");
    const [metadata, setMetadata] = createSignal<ChangelogsMetadata>();
    const [videoData, setVideoData] = createSignal<string>();

    const renderMarkdown = async (markdown: string) => {
        const currentMetadata = markdown.match(/---\n([\s\S]+?)\n---/);
        if (currentMetadata) {
            const metadataObject: ChangelogsMetadata = Object.fromEntries(currentMetadata[1].split("\n").map(line => line.split(": ")));

            document.title = metadataObject.title;
            setMetadata(metadataObject);
        }

        const result = matter(markdown);
        setMarkdownInHtml(DOMPurify.sanitize(await marked(result.content)));
    };

    createEffect(async () => {
        window.setMarkdown = async (markdown: string) => {
            sessionStorage.setItem("last-markdown", markdown);
            await renderMarkdown(markdown);
        };

        if (IS_DEV) {
            const lastMarkdown = sessionStorage.getItem("last-markdown");
            if (lastMarkdown)
                await renderMarkdown(lastMarkdown);
            else
                await renderMarkdown("Markdown not present");
        }
    }, []);

    createEffect(async () => {
        if (_.isNil(metadata())) return;
        const {heroVideo} = metadata()!;

        if (heroVideo) {
            const response = await fetch(heroVideo);
            if (!response.ok) {
                console.error("Failed to fetch video data", response);
                return;
            }

            const blob = await response.blob();
            setVideoData(URL.createObjectURL(blob));
        }
    }, [metadata]);

    return (
        <div class={"flex flex-1 flex-col items-center justify-center p-5"} onContextMenu={e => {
            if (!IS_DEV)
                e.preventDefault();
        }}>
            <TransitionGroup onEnter={(element, done) => {
                const animation = element.animate([{ opacity: 0 }, { opacity: 1 }], {
                    easing: "ease-in",
                    duration: 300
                });

                animation.finished.then(done);
            }}>
                <Show when={!_.isNil(metadata())}>
                    <>
                        <h1 class={"self-start text-left text-3xl font-bold mx-2"}>{metadata()?.title}</h1>
                        <p class={"self-start text-left text-sm text-zinc-500 my-1 mx-2"}>Version {window.BUILD_INFO.version} (build {window.BUILD_INFO.build})</p>
                        <Show when={!_.isNil(metadata()?.heroVideo)}>
                            <video class={clsx("py-2 aspect-video object-center w-max h-[65dvh]", {
                                "hidden": _.isNil(videoData()),
                                "rounded-sm": !_.isNil(videoData())
                            })} loop={true} autoplay={true} src={videoData()} contextMenu={"return false"} />
                        </Show>
                        <Show when={!_.isNil(metadata()?.heroImage)}>
                            <img class={"py-2 aspect-auto object-contain w-max h-[65dvh] rounded-sm"} draggable={false} src={metadata()?.heroImage} alt={"Image of Changelogs"}/>
                        </Show>
                        <Show when={!_.isNil(metadata()?.heroVideo)}>
                            <div class={clsx("flex items-center justify-center py-2 aspect-video h-[65dvh]", {
                                "hidden": !_.isNil(videoData())
                            })}>
                                <Spinner type={SpinnerType.tailSpin}/>
                            </div>
                        </Show>
                        <div class={"[&>ul]:list-disc self-start mx-7"} innerHTML={markdownInHtml()}/>
                    </>
                </Show>
            </TransitionGroup>
        </div>
    );
};

render(App, document.getElementById("app")!);
