import {defineConfig} from "vite";
import solid from "vite-plugin-solid";
import * as path from "path";
import {fileURLToPath} from "url";
import {viteSingleFile} from "vite-plugin-singlefile";
import viteTopLevelAwait from "vite-plugin-top-level-await";
import eslintPlugin from "@nabla/vite-plugin-eslint";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default defineConfig(() => ({
    base: "./",
    resolve: {
        alias: {
            "@src": path.join(__dirname, "src")
        }
    },
    plugins: [solid(), viteTopLevelAwait(), eslintPlugin({
        shouldLint: path => (path.endsWith(".ts") || path.endsWith(".tsx")) && path.includes("src")
    }), viteSingleFile()]
}));
