import {createEffect, createSignal, Signal} from "solid-js";

export default function useDarkMode(): Signal<boolean> {
    const [darkMode, setDarkMode] = createSignal(window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches);

    createEffect(() => {
        window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", event => {
            setDarkMode(event.matches);
        });
    }, []);

    return [darkMode, setDarkMode];
}
