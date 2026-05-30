# asdf-mdsmith

[![Lint](https://github.com/jeduden/asdf-mdsmith/actions/workflows/lint.yml/badge.svg)](https://github.com/jeduden/asdf-mdsmith/actions/workflows/lint.yml)
[![Test](https://github.com/jeduden/asdf-mdsmith/actions/workflows/test.yml/badge.svg)](https://github.com/jeduden/asdf-mdsmith/actions/workflows/test.yml)

[asdf](https://asdf-vm.com) plugin for
[mdsmith](https://github.com/jeduden/mdsmith) — a fast Markdown linter
and formatter written in Go.

The plugin installs the prebuilt `mdsmith` binary that ships with every
`vX.Y.Z` GitHub release. There is **no build step and no Go toolchain
required**: it downloads the asset for your platform, verifies its
SHA-256 against the release `checksums.txt`, and puts `mdsmith` on your
`PATH`.

## Dependencies

- `bash`, `curl`, and `git`
- `sha256sum` (Linux) or `shasum` (macOS) for checksum verification

These come preinstalled on virtually every developer machine and CI
image.

## Install

Add the plugin, then install and activate a version:

```bash
asdf plugin add mdsmith https://github.com/jeduden/asdf-mdsmith.git

# the latest stable release
asdf install mdsmith latest
asdf set mdsmith latest

# …or pin an exact version
asdf install mdsmith 0.27.0
asdf set mdsmith 0.27.0

mdsmith version
```

Once the plugin is listed in
[`asdf-vm/asdf-plugins`](https://github.com/asdf-vm/asdf-plugins), the
explicit URL becomes optional and `asdf plugin add mdsmith` resolves on
its own.

### `.tool-versions`

Pin the version per project the usual way:

```text
mdsmith 0.27.0
```

## Versions

```bash
asdf list all mdsmith   # every published version, oldest → newest
asdf latest mdsmith     # highest stable version
```

Versions are read directly from the mdsmith repository's git tags, so a
new release is installable the moment it is tagged — no plugin update
required.

## Supported platforms

mdsmith publishes binaries for, and this plugin installs on:

| OS    | Architectures   |
| ----- | --------------- |
| Linux | x86_64, aarch64 |
| macOS | x86_64, arm64   |

(Windows is distributed through the GitHub release and the npm / PyPI
packages; asdf itself is POSIX-shell based.)

## Environment variables

- `GITHUB_API_TOKEN` *(optional)* — sent as a bearer token on
  downloads. It only raises GitHub's unauthenticated rate limit and is
  never required, since every request targets a public release asset.

## Contributing

The `bin/` callbacks and `lib/utils.bash` are plain Bash. Before
opening a PR, run the same checks CI runs:

```bash
shellcheck -x -P SCRIPTDIR bin/* lib/*.bash
shfmt -d bin lib       # add -w to auto-format
```

## License

[MIT](LICENSE) — same license as mdsmith.
