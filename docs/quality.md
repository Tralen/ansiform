# Quality

Ansiform checks formatting, linting and secrets in CI. The same commands run locally.

## Formatting

Fourmolu 0.21.0.0 formats the library, the examples and the tests. The configuration lives in `fourmolu.yaml`: four spaces, leading commas, leading import and export lists, automatic Haddock style and no Unicode syntax.

```sh
fourmolu --mode check $(find src examples test -name '*.hs')
fourmolu --mode inplace $(find src examples test -name '*.hs')
```

The first command reports files that would change and fails when any file is not formatted. The second rewrites them.

## Linting

HLint 3.10 checks the same three directories:

```sh
hlint src examples test
```

The command exits with a failure when it finds a hint. The project keeps the hint count at zero, so new code must be clean or the rule must be discussed before adding an ignore.

## Secrets

Gitleaks scans the working tree and the full history. The CI workflow uses `gitleaks/gitleaks-action` v3 and the local binary is v8.30.1:

```sh
gitleaks git --redact --log-opts="--all"
gitleaks dir --redact .
```

The `--redact` flag prevents a finding from printing the secret itself. A finding blocks the release until the secret is rotated and the history is cleaned.

## Continuous integration

`.github/workflows/ci.yml` has two jobs:

- `build` runs on Ubuntu, `macos-15-intel`, `macos-15` and Windows with GHC 9.2.8 and 9.14.1, as allowed by the available bindists.
- `quality` runs Fourmolu and HLint on Ubuntu with pinned tool versions and verified checksums.

`.github/workflows/gitleaks.yml` runs the secret scan on pushes, pull requests and manual dispatches.

The tool versions are pinned in the workflow. Update the version, the release URL and the checksum together.

## Local setup

Fourmolu and HLint have release binaries for Linux, macOS and Windows. They can also be installed with Cabal:

```sh
cabal install --installdir="$HOME/.local/bin" --overwrite-policy=always fourmolu-0.21.0.0 hlint-3.10
```

Gitleaks is distributed as a single binary from its GitHub releases. The release workflow does not need any of these tools; it uses the Hackage and GitHub tokens described in `docs/releasing.md`.
