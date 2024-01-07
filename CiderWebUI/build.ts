import {glob} from "glob";
import ora from "ora";
import * as path from "path";
import * as esbuild from "esbuild";
import * as async from "modern-async";
import fs from "fs-extra";
import os from "os";
import * as child_process from "child_process";
import {fileURLToPath} from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const injectionScripts = await glob('src/injections/*');

async function buildInjections() {
    const spinner = ora("Building injection scripts").start();
    const targets = await async.asyncMap(injectionScripts, target => path.basename(target));
    await async.asyncForEach(targets, async target => {
        spinner.text = `Building ${target}`;
        const {errors, warnings} = await esbuild.build({
            entryPoints: [path.resolve(__dirname, 'src', 'injections', target, 'index.ts')],
            minify: true,
            treeShaking: true,
            tsconfig: path.resolve(__dirname, 'tsconfig.json'),
            bundle: true,
            outfile: path.resolve(__dirname, 'dist', `${target}.js`),
            platform: 'browser',
            target: 'safari16'
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

        const outputFiles = await glob('dist/**/*', {
            absolute: true
        });
        fs.writeFile(path.join(__dirname, 'files.xcfilelist'), outputFiles.join(os.EOL));
    });
}

if (process.argv.includes('--build-injections')) {
    const proc = child_process.spawn(`${path.join(__dirname, 'node_modules', '.bin', 'vite')} build`, [], {
        shell: true,
        cwd: process.cwd(),
        env: {...process.env, FORCE_COLOR: '1'},
        stdio: ['inherit', 'pipe', 'pipe'],
    });

    proc.stdout.pipe(process.stdout);
    proc.stderr.pipe(process.stderr);

    proc.once('exit', async exitCode => {
        if (exitCode !== 0)
            process.exit(exitCode);

        await buildInjections();
    })
}
