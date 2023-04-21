import * as fs from "fs";
import ora from "ora";
import * as path from "path";
import downloadFile from "../utils/download-file";

const cwd = process.env.CWD ?? process.cwd();
const googleServicePath = path.join(cwd, 'Cider', 'GoogleService-Info.plist')
const exists = fs.existsSync(googleServicePath);
if (exists)
    fs.unlinkSync(googleServicePath);

const spinner = ora(`${exists ? "Refetching" : "Fetching"} GoogleService-Info.plist to ${googleServicePath}`).start();

try {
    await downloadFile('https://firebasestorage.googleapis.com/v0/b/cider-collective.appspot.com/o/GoogleService-Info-macOS.plist?alt=media&token=191e51ff-51b6-4e72-9d60-fb63e2aa828d', googleServicePath);
} catch (err) {
    spinner.fail(`Failed to fetch GoogleService-Info.plist: ${err}`);
    process.exit(1);
} finally {
    spinner.succeed(`Successfully fetched GoogleService-Info.plist`);
}
