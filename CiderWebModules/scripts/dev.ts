import {fileURLToPath} from "url";
import * as path from "path";
import {createServer, InlineConfig, mergeConfig, UserConfig} from "vite";
import buildConfig from "../vite.config";
import * as cheerio from "cheerio";
import solidPlugin from "vite-plugin-solid";
import {glob} from "glob";
import mkcert from "vite-plugin-mkcert";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(path.resolve(__filename, ".."));

const routes = await glob("src/routes/*");

const baseConfig = buildConfig({
    command: "serve",
    mode: "development"
});
const server = await createServer(mergeConfig<UserConfig, InlineConfig>(baseConfig, {
    configFile: false,
    root: __dirname,
    server: {
        port: 5173
    },
    build: {
        rollupOptions: {
            input: path.resolve(__dirname, "index.html")
        }
    },
    plugins: [solidPlugin({
        dev: true,
        hot: true,
        ssr: false
    }), {
        name: "web-modules-dev-server",
        transformIndexHtml: {
            handler(html, {originalUrl}) {
                const url = new URL(`http://localhost:5173${originalUrl}`);
                const $ = cheerio.load(html);

                if (url.pathname === "/") {
                    $("<script></script>").attr("type", "module").text("import './src/index.scss';").appendTo("head");
                    $("<title></title>").text("CiderWebModules").appendTo("head");

                    const list = $("<ul></ul>");
                    routes.forEach(route => {
                        const name = path.basename(route);
                        $("<li></li>").append($("<a></a>").attr({
                            href: `/${name}`,
                            style: "text-decoration: none; color: lightblue;"
                        }).text(name)).appendTo(list);
                    });

                    $("<h1 class='text-3xl font-bold'></h1>").text("CiderWebModules").appendTo("body");
                    list.appendTo("body");
                } else {
                    $("<script></script>").attr({
                        type: "module",
                        src: `./src/routes${url.pathname}`
                    }).appendTo("body");
                }

                return $.html();
            }
        }
    }, ...(process.versions.bun ? [] : [mkcert({})])]
}));

await server.listen();

server.printUrls();
server.bindCLIShortcuts({
    print: true
});
