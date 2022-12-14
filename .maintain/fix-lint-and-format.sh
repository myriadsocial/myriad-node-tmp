#!/usr/bin/env bash

set -e

pushd .

# The following line ensure we run from the project root
PROJECT_ROOT=`git rev-parse --show-toplevel`
cd $PROJECT_ROOT

echo "Fix Lint"
cargo +nightly clippy --workspace --all-targets --fix
echo "Fix Format"
cargo +nightly fmt --all

popd
