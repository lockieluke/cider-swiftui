import {defineConfig} from 'vite'
import solid from 'vite-plugin-solid'
import {viteSingleFile} from "vite-plugin-singlefile";
import {ViteMinifyPlugin} from "vite-plugin-minify";
import * as path from 'path';
import {fileURLToPath} from "url";
import {injectionScripts} from "./build";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default defineConfig(() => ({
  build: {
    rollupOptions: {
      input: {
        'am-auth': path.join(__dirname, 'entries', 'am-auth.html')
      },
      external: injectionScripts
    },
    outDir: 'dist'
  },
  base: './',
  resolve: {
    alias: {
      '@src': path.join(__dirname, 'src')
    }
  },
  plugins: [solid(), viteSingleFile(), ViteMinifyPlugin()]
}));
