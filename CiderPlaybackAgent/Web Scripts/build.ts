import * as esbuild from 'esbuild';
const lodashTransform = require('esbuild-plugin-lodash');

(async () => {
    await esbuild.build({
        entryPoints: ['src/index.ts'],
        bundle: true,
        outfile: 'dist/index-cpa.js',
        minify: true,
        target: 'safari15',
        treeShaking: true,
        platform: 'browser',
        logLevel: 'info',
        plugins: [lodashTransform()]
    });
})();
