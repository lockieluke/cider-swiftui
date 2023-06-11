import * as esbuild from 'esbuild';
const lodashTransform = require('esbuild-plugin-lodash');

(async () => {
    await esbuild.build({
        entryPoints: ['src/index.ts'],
        bundle: true,
        outfile: 'dist/ciderplaybackagent.js',
        minify: true,
        target: 'safari15',
        treeShaking: true,
        platform: 'browser',
        logLevel: 'info',
        plugins: [lodashTransform()],
        legalComments: 'none' /* we will show licences in the main client as this script is run in a headless WKWebView */
    });
})();
