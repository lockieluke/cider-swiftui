import {generateLicenseFile} from "generate-license-file";
import {fileURLToPath} from "url";
import * as path from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(path.resolve(__filename, ".."));

await generateLicenseFile(path.join(__dirname, "package.json"), path.join(__dirname, "THIRD_PARTY_LICENCES.txt"), {
    replace: {
        "@kobalte/core@0.12.3": path.join(__dirname, "node_modules", "@kobalte", "core", "LICENSE.md")
    }
});
