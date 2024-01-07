import { defineConfig } from 'vite'
import solid from 'vite-plugin-solid'
import {viteSingleFile} from "vite-plugin-singlefile";
import {ViteMinifyPlugin} from "vite-plugin-minify";
import ora from 'ora';
import * as esbuild from 'esbuild';
import * as async from 'modern-async';
import * as path from 'path';
import fs from "fs-extra";
import {glob} from "glob";
import * as os from "os";

export default defineConfig(() => ({
  build: {
    rollupOptions: {
      input: {
        'am-auth': path.join(__dirname, 'entries', 'am-auth.html')
      }
    },
    outDir: 'dist'
  },
  base: './',
  resolve: {
    alias: {
      '@src': path.join(__dirname, 'src')
    }
  },
  plugins: [{
    name: 'build-injection-scripts',
    async closeBundle() {
      const spinner = ora("Building injection scripts").start();
      const targets = await async.asyncMap(await glob('src/injections/*'), target => path.basename(target));
      await async.asyncForEach(targets, async target => {
        spinner.text = `Building ${target}`;
        const {errors} = await esbuild.build({
          entryPoints: [path.join(__dirname, 'src', 'injections', target, 'index.ts')],
          minify: true,
          treeShaking: true,
          tsconfig: path.join(__dirname, 'tsconfig.json'),
          bundle: true,
          outfile: path.join(__dirname, 'dist', `${target}.js`),
          platform: 'browser',
          target: 'safari16'
        });
        if (errors.length > 0) {
          spinner.fail(`Failed to build ${target}`);
          process.exit(1);
        }

        spinner.succeed(`Built ${target}`);

        const outputFiles = await glob('dist/**/*', {
          absolute: true
        });
        fs.writeFile(path.join(__dirname, 'files.xcfilelist'), outputFiles.join(os.EOL));
      });
    }
  }, solid(), viteSingleFile(), ViteMinifyPlugin()]
}));
