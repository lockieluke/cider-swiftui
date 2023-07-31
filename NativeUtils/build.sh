#!/bin/bash
# from https://chinedufn.github.io/swift-bridge/building/xcode-and-cargo/index.html
set -e

export PATH="$HOME/.cargo/bin:$PATH"

# Without this we can't compile on MacOS Big Sur
# https://github.com/TimNN/cargo-lipo/issues/41#issuecomment-774793892
#if [[ -n "${DEVELOPER_SDK_DIR:-}" ]]; then
#  export LIBRARY_PATH="${DEVELOPER_SDK_DIR}/MacOSX.sdk/usr/lib:${LIBRARY_PATH:-}"
#fi

TARGETS="${TARGETS:-aarch64-apple-darwin}" #x86_64-apple-darwin
if [[ $CONFIGURATION == "Release" ]]; then
    echo "BUIlDING FOR RELEASE ($TARGETS)"
    cargo +nightly lipo --release --targets $TARGETS
    ln -f target/universal/release/libnative_utils.a target/universal/
else
    echo "BUIlDING FOR DEBUG ($TARGETS)"
    cargo +nightly lipo --targets $TARGETS
    ln -f target/universal/debug/libnative_utils.a target/universal/
fi
