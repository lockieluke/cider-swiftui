import * as https from "https";
import * as fs from "fs";
import * as path from "path";

const cwd = process.env.CWD ?? process.cwd();
const googleServicePath = path.join(cwd, 'Cider', 'GoogleService-Info.plist')
const exists = fs.existsSync(googleServicePath);
if (exists)
    fs.unlinkSync(googleServicePath);

console.log(`${exists ? "Refetching" : "Fetching"} GoogleService-Info.plist to ${googleServicePath}`);
const file = fs.createWriteStream(googleServicePath);
https.get('https://firebasestorage.googleapis.com/v0/b/cider-collective.appspot.com/o/GoogleService-Info-macOS.plist?alt=media&token=191e51ff-51b6-4e72-9d60-fb63e2aa828d', res => res.pipe(file).on('finish', () => console.log("Done")))
    .on('error', err => console.error(err));
