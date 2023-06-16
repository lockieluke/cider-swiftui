#!/bin/sh

#  ci_post_clone.sh
#  Cider
#
#  Copyright © 2023 Cider Collective. All rights reserved.

cd $CI_WORKSPACE

brew bundle

# Install Node and Yarn v3
brew install node corepack
echo "Installed Node `node --version` with corepack `corepack --version`"
corepack enable
corepack prepare yarn@3.6.0 --activate

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain none
source "$HOME/.cargo/env"
rustup +nightly target add aarch64-apple-darwin x86_64-apple-darwin
rustup default nightly
echo "Installed Rust `rustc --version`"

# Install cargo dependencies
cargo +nightly install cargo-lipo
echo "Installed cargo-lipo `cargo lipo --version`"

# Configure Yarn
yarn config set -H enableImmutableInstalls false

# Compile stuff and add files
task install-deps:all-js
task build:all-js
task fetch:google-services
task build:discord-rpc-lib
task build:native-utils-lib
