import {glob} from "glob";
import ora from "ora";
import * as path from "path";
import * as esbuild from "esbuild";
import {sassPlugin} from "esbuild-sass-plugin";
import * as async from "modern-async";
import fs from "fs-extra";
import os from "os";
import {fileURLToPath} from "url";
import {build} from "vite";
import * as cheerio from "cheerio";
import buildConfig from "../vite.config";
import exitHook from "async-exit-hook";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(path.resolve(__filename, ".."));

const tmpDir = path.resolve(__dirname, "dist", "tmp");
const injectionScripts = await glob("src/injections/*");
const routes = new Bun.Glob("src/routes/**/index.{tsx,ts}");

const cleanup = async (done: () => void) => {
    await fs.remove(tmpDir);
    done();
};

exitHook(cleanup);
exitHook.uncaughtExceptionHandler(async (error, done) => {
    console.error(error);
    await cleanup(done);
});
exitHook.unhandledRejectionHandler(async (error, done) => {
    console.error(error);
    await cleanup(done);
});

const spinner = ora("Building routes").start();

const templateHtml = await fs.readFile(path.resolve(__dirname, "index.html"), "utf-8");
await fs.mkdirp(tmpDir);
for await (const route of routes.scan()) {
    const $ = cheerio.load(templateHtml);
    await fs.ensureDir(tmpDir);

    const htmlName = `${path.basename(path.dirname(route))}.html`;
    const destPath = path.resolve(__dirname, "dist", htmlName);
    await fs.remove(destPath);

    const tmpHtmlPath = path.resolve(__dirname, "dist", "tmp", htmlName);
    $("<script></script>").attr("type", "module").text("import '../../src/index.scss';").appendTo("head");
    $("<script></script>").attr({
        type: "module",
        src: path.relative(path.dirname(tmpHtmlPath), path.resolve(__dirname, route))
    }).appendTo("head");
    await fs.writeFile(tmpHtmlPath, $.html());

    try {
        await build({
            ...buildConfig,
            build: {
                rollupOptions: {
                    input: tmpHtmlPath
                },
                outDir: "./",
                emptyOutDir: false
            },
            base: "./"
        });
    } catch (error) {
        spinner.fail(`Failed to build ${route}`);
        process.exit(1);
    } finally {
        await fs.move(path.resolve(tmpDir, htmlName), destPath);
    }

    spinner.succeed(`Built ${route}`);
}

spinner.start("Building injections");
const targets = await async.asyncMap(injectionScripts, target => path.basename(target));
await async.asyncForEach(targets, async target => {
    spinner.text = `Building ${target}`;
    const {errors, warnings} = await esbuild.build({
        entryPoints: [path.resolve(__dirname, "src", "injections", target, "index.ts")],
        minify: true,
        treeShaking: true,
        tsconfig: path.resolve(__dirname, "tsconfig.json"),
        bundle: true,
        outfile: path.resolve(__dirname, "dist", `${target}.js`),
        platform: "browser",
        target: "safari16",
        plugins: [sassPlugin({
            type: "css-text",
            style: "compressed"
        })]
    });
    if (errors.length > 0) {
        spinner.fail(`Failed to build ${target}`);
        process.exit(1);
    }

    if (warnings.length > 0) {
        spinner.warn(`Built ${target} with warnings`);
        return;
    }

    spinner.succeed(`Built ${target}`);
});

await fs.writeFile(path.join(__dirname, "files.xcfilelist"), (await glob("dist/**/*", {
    absolute: true,
    nodir: true
})).filter(pathname => path.basename(pathname) !== "tmp").join(os.EOL));
await fs.writeFile(path.join(__dirname, "source-files.xcfilelist"), (await glob("src/**/*", {
    absolute: true,
    nodir: true
})).join(os.EOL));
