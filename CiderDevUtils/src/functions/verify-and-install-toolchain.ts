import * as fs from "fs";
import ora from "ora";
import shelljs from "shelljs";
import downloadFile from "../utils/download-file";
import promptSync from "prompt-sync";
import isAppleSilicon from "../utils/is-apple-silicon";
const prompt = promptSync();

const spinner = ora("Verifying toolchain").start();

const xcode = shelljs.exec("xcodebuild -version | grep \"Xcode \"", { silent: true });
if (xcode.code !== 0) {
    spinner.fail("Xcode command line tools are not installed");
    process.exit(1);
} else if (!xcode.stdout.startsWith("Xcode 14.")) {
    spinner.fail("Requires Xcode 14.0 or higher");
    process.exit(1);
}

const rustc = shelljs.exec("rustc --version", { silent: true });
if (rustc.code !== 0) {
    spinner.fail("rustc is not installed");
    process.exit(1);
}

const cargo = shelljs.exec("cargo --version", { silent: true });
if (cargo.code !== 0) {
    spinner.fail("cargo is not installed");
    process.exit(1);
}

const cargoLipo = shelljs.exec("cargo-lipo --version", { silent: true });
if (cargoLipo.code !== 0) {
    spinner.fail("cargo-lipo is not installed");
    process.exit(1);
}

const task = shelljs.exec("task --version", { silent: true });
if (task.code !== 0) {
    spinner.fail("Taskfile is not installed");
    process.exit(1);
}

const yarn3 = shelljs.exec("yarn --version", { silent: true });
if (yarn3.code !== 0 || !yarn3.stdout.startsWith("3")) {
    spinner.fail("Yarn 3 is not installed");
    process.exit(1);
}

const node = shelljs.exec("node --version", { silent: true });
if (node.code !== 0) {
    spinner.fail("NodeJS is not installed, what did you use to run this script?");
    process.exit(1);
}

const ruby = shelljs.exec("ruby --version", { silent: true });
if (ruby.code !== 0) {
    spinner.fail("Ruby is not installed");
    process.exit(1);
}

const coke = shelljs.exec("coke --version", { silent: true });
if (coke.code !== 0) {
    spinner.fail("Coke is not installed");
    const installCoke = prompt("Install Coke? [Y/n] ").toLowerCase();
    if (installCoke !== 'y')
        process.exit(1);

    const installPath: string = '/usr/local/bin/coke';
    if (fs.existsSync(installPath))
        fs.unlinkSync(installPath);
    spinner.start(`Installing Coke to ${installPath}`);

    try {
        await downloadFile(`https://github.com/ciderapp/coke/releases/latest/download/coke-${isAppleSilicon ? 'arm64' : 'x64'}`, installPath);
    } catch (err) {
        spinner.fail(`Failed to install Coke: ${err}`);
        process.exit(1);
    }
    shelljs.exec(`chmod +x ${installPath}`);

    spinner.succeed("Coke installed, verifying other tools");
}

const bundler2 = shelljs.exec("bundle --version", { silent: true });
if (bundler2.code !== 0 || !bundler2.stdout.replace("Bundler version ", "").startsWith("2")) {
    spinner.fail("Bundler 2 is not installed, run `gem install bundler`");
    process.exit(1);
}

const cocoapods = shelljs.exec("pod --version", { silent: true });
if (cocoapods.code !== 0) {
    spinner.fail("Cocoapods is not installed, run `[sudo]gem install cocoapods`");
    process.exit(1);
}

spinner.succeed("Toolchain verified");
