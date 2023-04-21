import * as fs from "fs";
import https from "https";

export default function downloadFile(url: string, filename: string) {
    return new Promise<void>((resolve, reject) => {
        const file = fs.createWriteStream(filename);
        https.get(url, res => res.pipe(file).on('finish', () => resolve()))
            .on('error', err => reject(err));
    });
}
