#!/usr/bin/env bash

set -e -u -o pipefail # Fail on error

dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd $dir

# If editing this file, you may also want to update windows/s3_prerelease.cmd

client_dir="$dir/../.."
bucket_name=${BUCKET_NAME:-}
platform=${PLATFORM:-}

if [ "$bucket_name" = "" ]; then
  echo "No BUCKET_NAME"
  exit 1
fi

if [ "$platform" = "" ]; then
  echo "No PLATFORM"
  exit 1
fi

echo "Loading release tool"
"$client_dir/packaging/goinstall.sh" "github.com/keybase/release"
release_bin="$GOPATH/bin/release"

echo "Creating index files"
if [ "$platform" = "darwin" ]; then
  "$release_bin" index-html --bucket-name="$bucket_name" --prefixes="darwin/" --upload="darwin/index.html"
  "$release_bin" index-html --bucket-name="$bucket_name" --prefixes="electron-sourcemaps/" --upload="electron-sourcemaps/index.html"
elif [ "$platform" = "linux" ]; then
  "$release_bin" index-html --bucket-name="$bucket_name" --prefixes="linux_binaries/deb/" --upload="linux_binaries/deb/index.html"
  "$release_bin" index-html --bucket-name="$bucket_name" --prefixes="linux_binaries/rpm/" --upload="linux_binaries/rpm/index.html"
elif [ "$platform" = "windows" ]; then
  "$release_bin" index-html --bucket-name="$bucket_name" --prefixes="windows/" --upload="windows/index.html"
else
  echo "Invalid platform: $platform"
  exit 1
fi

echo "Linking latest ($platform)"
"$release_bin" latest --bucket-name="$bucket_name" --platform="$platform"

echo "Checking if we need to promote a release for testing ($platform)"
"$release_bin" promote-test-releases --bucket-name="$bucket_name" --platform="$platform"

echo "Checking if we need to promote a release ($platform)"
"$release_bin" promote-releases --bucket-name="$bucket_name" --platform="$platform"
