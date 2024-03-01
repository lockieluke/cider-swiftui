import type {Config} from "tailwindcss";

declare const require: (id: string) => void;

export default {
    darkMode: "class",
    content: [
        "./src/**/*.{html,js,jsx,md,mdx,ts,tsx}"
    ],
    presets: [require("./ui.preset.js")]
} satisfies Config;
