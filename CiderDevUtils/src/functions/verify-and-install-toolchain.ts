import ora from "ora";
import shelljs from "shelljs";
import promptSync from "prompt-sync";

const prompt = promptSync();

const spinner = ora("Verifying toolchain").start();

const xcode = shelljs.exec("xcodebuild -version | grep \"Xcode \"", { silent: true });
if (xcode.code !== 0) {
    spinner.fail("Xcode command line tools are not installed");
    process.exit(1);
} else if (!xcode.stdout.startsWith("Xcode 15.")) {
    spinner.fail("Requires Xcode 15.0 or higher");
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

spinner.succeed("Toolchain verified");
