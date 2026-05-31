#!/usr/bin/env bash

# Shared helpers for the asdf-mdsmith plugin, sourced by every bin/
# callback.
#
# mdsmith ships one prebuilt, statically linked binary per platform on
# each GitHub release, named "mdsmith-<os>-<arch>" (e.g.
# mdsmith-linux-amd64), alongside a "checksums.txt" file. This plugin
# downloads the asset matching the running host and verifies its
# SHA-256 against that file before installing it. No build step, no Go
# toolchain, and no GitHub token are required.

set -euo pipefail

GH_REPO="https://github.com/jeduden/mdsmith"
TOOL_NAME="mdsmith"
# shellcheck disable=SC2034 # referenced by callers that source this file.
TOOL_TEST="mdsmith version"

fail() {
	echo -e "asdf-${TOOL_NAME}: $*"
	exit 1
}

# Shared curl flags. A GITHUB_API_TOKEN, when present, only raises the
# unauthenticated rate limit; it is never required, because every
# request targets a public release asset over HTTPS.
curl_opts=(-fsSL)
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts+=("-H" "Authorization: token ${GITHUB_API_TOKEN}")
fi

# sort_versions orders dotted versions oldest-to-newest and keeps
# pre-release suffixes ahead of their final release (1.2.3-rc1 < 1.2.3).
sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n |
		awk '{print $2}'
}

# list_all_versions prints every published mdsmith version, one per
# line, with the leading "v" stripped (asdf expects bare X.Y.Z). It
# reads tags straight from the git remote, so it needs no API call and
# no token. --refs drops the "^{}" dereference rows annotated tags add.
list_all_versions() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' |
		cut -d/ -f3- |
		sed 's/^v//'
}

# get_platform maps "uname -s" onto the GOOS token mdsmith names its
# assets with. asdf is a POSIX-shell tool, so only Linux and macOS are
# in scope; the Windows binary is unreachable here.
get_platform() {
	local os
	os="$(uname -s)"
	case "$os" in
	Linux) echo "linux" ;;
	Darwin) echo "darwin" ;;
	*) fail "unsupported operating system: ${os} (mdsmith ships linux and darwin binaries)" ;;
	esac
}

# get_arch maps "uname -m" onto the GOARCH token mdsmith names its
# assets with.
get_arch() {
	local arch
	arch="$(uname -m)"
	case "$arch" in
	x86_64 | amd64) echo "amd64" ;;
	aarch64 | arm64) echo "arm64" ;;
	*) fail "unsupported architecture: ${arch} (mdsmith ships amd64 and arm64 binaries)" ;;
	esac
}

# asset_name returns the release-asset filename for the running host,
# e.g. "mdsmith-linux-amd64".
asset_name() {
	echo "${TOOL_NAME}-$(get_platform)-$(get_arch)"
}

# sha256_of prints the lowercase SHA-256 of a file using whichever tool
# the host provides: sha256sum on Linux, shasum on macOS.
sha256_of() {
	local file="$1"
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$file" | awk '{print $1}'
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$file" | awk '{print $1}'
	else
		fail "no sha256sum or shasum on PATH to verify the download"
	fi
}

# download_release fetches the host's binary plus the release
# checksums file into download_path, then aborts unless the binary's
# SHA-256 matches the published value. On success only the binary
# remains in download_path for bin/install to copy.
download_release() {
	local version="$1"
	local download_path="$2"
	local asset url checksums_url expected actual

	asset="$(asset_name)"
	url="${GH_REPO}/releases/download/v${version}/${asset}"
	checksums_url="${GH_REPO}/releases/download/v${version}/checksums.txt"

	echo "* Downloading ${TOOL_NAME} ${version} (${asset}) ..."
	curl "${curl_opts[@]}" -o "${download_path}/${TOOL_NAME}" "$url" ||
		fail "could not download ${url}"

	echo "* Verifying checksum ..."
	curl "${curl_opts[@]}" -o "${download_path}/checksums.txt" "$checksums_url" ||
		fail "could not download ${checksums_url}"

	expected="$(awk -v name="$asset" '$2 == name {print $1}' "${download_path}/checksums.txt")"
	[ -n "$expected" ] || fail "no checksum for ${asset} in checksums.txt"
	actual="$(sha256_of "${download_path}/${TOOL_NAME}")"
	[ "$expected" = "$actual" ] ||
		fail "checksum mismatch for ${asset}: expected ${expected}, got ${actual}"
	echo "* Checksum verified"

	rm -f "${download_path}/checksums.txt"
}
