import type {Config} from "tailwindcss";

declare const require: (id: string) => Partial<Config>;

export default {
    darkMode: "media",
    content: [
        "./src/**/*.{html,js,jsx,md,mdx,ts,tsx}"
    ],
    presets: [require("./ui.preset.js")],
} satisfies Config;
