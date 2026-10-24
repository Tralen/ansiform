# Releasing

This checklist covers the Hackage and GitHub release of Ansiform. Update it as the release process evolves. The README defines the versioning scheme and the single source of the version.

## Current status

- Package: `ansiform`. The name is already registered on Hackage.
- Version: 1.1.0.0, the release that removes the unlawful `Eq` instances and adds `printerName`.
- The previous published release is 1.0.0.1. The 1.1.0.0 candidate is built from the signed tag and reviewed before publication.
- License: MIT.
- `cabal sdist` produces a complete source distribution with sources, docs, examples, tests, README, changelog and LICENSE.
- Haddock builds with 100% coverage for the public functions and types. The remaining warnings are only about module re-exports.
- CI: `.github/workflows/ci.yml` builds, tests, checks, documents and creates the source distribution on Ubuntu, `macos-15-intel`, `macos-15` and Windows with GHC 9.2.8 and GHC 9.14.1. The quality job checks Fourmolu and HLint. `.github/workflows/gitleaks.yml` scans the history for secrets.
- GitHub: public at <https://github.com/Tralen/ansiform>; the local remote is `git@github.com:Tralen/ansiform.git`.
- `source-repository`, `homepage` and `bug-reports` are set to the GitHub URL.
- The history has been rewritten and contains no personal paths.
- Tag `1.0.0.1` and its GitHub release are published at <https://github.com/Tralen/ansiform/releases/tag/1.0.0.1>.
- Hackage: 1.0.0.1 is published at <https://hackage.haskell.org/package/ansiform-1.0.0.1>, with documentation uploaded.
- The 1.0.0 release marked the library stable and drew every prefilled field when a form opens. It includes the editable form fields, `Ansiform.Line`, `readKeyPress`, the lone-Escape fix and the platform documentation from 0.8.0 through 0.9.0.6.
- 1.0.0.1 added Fourmolu, HLint, gitleaks, the Intel macOS CI job and the manual release workflow. 1.0.0.2 applied the non-breaking compliance patch, and 1.0.0.3 added the QuickCheck and golden tests.
- 1.1.0.0 removes the unlawful `Eq` instances from `Printer`, `Section` and `Page` and adds `printerName`. It is the first release whose tag is signed with the configured SSH key; the 1.0.0.1 tag remains annotated and unsigned because it was published before the key was configured.

## Credentials

Publishing needs two credentials. Local builds, tests, Haddock, formatting, linting and `cabal sdist` do not use them.

### Hackage

Store the token in the global Cabal configuration, outside any `repository` stanza, and restrict the file:

```sh
chmod 600 ~/.cabal/config
```

Add the line `token: <value>` to `~/.cabal/config`. Cabal sends it as `Authorization: X-ApiKey`, so the value never enters `argv` or the environment. Verify only the entry count and the mode, never the value:

```sh
grep -c '^token:' ~/.cabal/config
stat -c '%a' ~/.cabal/config
```

Then upload without a token argument:

```sh
cabal upload dist-newstyle/sdist/ansiform-<version>.tar.gz
cabal upload --documentation dist-newstyle/ansiform-<version>-docs.tar.gz
```

The automated release stores the token as an environment secret named `HACKAGE_TOKEN` in the GitHub environment `release` and exposes it to the upload step as an environment variable. Do not add the token or the location of the secret manager to the repository.

New Hackage accounts must be added to the uploaders group before the first upload. Ask two confirmed uploaders to endorse the account through the link in the account email, or email `hackage-trustees@haskell.org` with the Hackage username and a link to the repository. Uploads return HTTP 403 until the account is approved.

### GitHub

Pushes use SSH. Configure an SSH key for your GitHub account with your own local tooling; no key paths belong in this repository.

1. Add the public key to GitHub under **Settings > SSH and GPG keys**.
2. Test the connection:

   ```sh
   ssh -T git@github.com
   ```

3. Verify that the remote uses SSH:

   ```sh
   git remote -v
   git remote set-url origin git@github.com:Tralen/ansiform.git
   ```

The repository must be public for the package links and badges to work. Pushes still require a key belonging to an account with write access. `GITHUB_TOKEN` is not used automatically by `git push`; it is only for the GitHub API or `gh`. The release workflow uses the token that GitHub provides to create the release.

Never print the values of the tokens or commit the location of your secrets.

### Signed tags

The `1.0.0.1` tag is annotated and unsigned because the key was configured afterwards. The `1.1.0.0` tag is the first one signed with SSH. To use another key format, configure it once.

SSH signing uses an existing SSH key and works with Git 2.34 or later:

1. Tell Git to use the public key:

   ```sh
   git config --global gpg.format ssh
   git config --global user.signingkey <path-to-public-key>
   git config --global tag.gpgSign true
   ```

2. Add the same public key to GitHub as a Signing Key under Settings > SSH and GPG keys > New SSH key. The authentication entry is separate and can stay as it is.
3. For local verification, list the key in an allowed signers file and point Git to it:

   ```sh
   echo "<github-noreply-email> namespaces=\"git\" $(cat <path-to-public-key>)" > <allowed-signers-file>
   git config --global gpg.ssh.allowedSignersFile <allowed-signers-file>
   ```

4. Create and verify a signed tag:

   ```sh
   git tag -s <version> -m "ansiform <version>"
   git tag -v <version>
   ```

For OpenPGP, create a key with `gpg --full-generate-key`, set `user.signingkey` to the long key ID, export the public key with `gpg --armor --export <key-id>` and add it to GitHub as a GPG key. Use `git tag -s` and `git tag -v` in the same way.

## Automated release

`.github/workflows/release.yml` publishes a version through `workflow_dispatch`. It has two jobs:

- `candidate` checks out the tag, verifies that the tag and the version in `ansiform.cabal` match, builds, tests, checks, builds the Haddock tarball and the source distribution, uploads both as Hackage candidates and stores them with a `SHA256SUMS` file as a workflow artifact.
- `publish` runs only when the `publish` input is true. It verifies the checksums, publishes the exact artifacts to Hackage and creates the GitHub release with generated notes.

Both jobs use the `release` environment. A solo maintainer does not need required reviewers; if reviewers are enabled, both the candidate and the publish job wait for approval.

### Configuring the release environment

1. Open **Settings > Environments** and create an environment named `release`.
2. Under **Environment secrets**, add a secret named `HACKAGE_TOKEN`. Paste the Hackage token value as the secret value; do not paste the name or `$HACKAGE_TOKEN`, and do not create an Actions variable, because variables are plaintext.
3. Under **Deployment branches and tags**, allow `master` and the release tags. The workflow is dispatched from a branch, so the selected branch must be allowed.
4. Required reviewers are optional. If enabled, both jobs wait for approval.

The workflow reads the secret with `secrets.HACKAGE_TOKEN` and exposes it to the upload steps as the `HACKAGE_TOKEN` environment variable. The token is never printed and never enters the repository.

1. Push the final commit and the tag. The tag uses the version without a `v` prefix:

   ```sh
   git push origin master
   git tag -a <version> -m "ansiform <version>"
   git push origin <version>
   ```

   If a signing key is configured, use `git tag -s <version> -m "ansiform <version>"` and verify it with `git tag -v <version>`. Without a key, keep the annotated tag.

2. Run the workflow with `publish` disabled and inspect the candidate at `https://hackage.haskell.org/package/ansiform/candidates`. Check the rendered documentation, the dependency bounds and the build report.
3. Run the workflow again with `publish` enabled. The environment approval is the explicit authorization.
4. Check the public package page, the documentation links, the GitHub release and the attached artifacts.

The workflow is the preferred path because it builds from the tag and keeps the token outside the local machine. The manual process below remains available and produces the same artifacts.

## Manual release

### Before the release

1. Configure an SSH key for GitHub and confirm write access to the repository.
2. Verify the remote and start from a clean tree:

   ```sh
   git remote -v
   git status
   git push -u origin master
   ```

3. The repository metadata is already set in `ansiform.cabal`:

   ```cabal
   homepage:       https://github.com/Tralen/ansiform
   bug-reports:    https://github.com/Tralen/ansiform/issues
   source-repository head
     type:     git
     location: https://github.com/Tralen/ansiform.git
   ```

   The `source-repository` section removes the `no-repository` warning from `cabal check`.

4. Check the package name on Hackage again. Names are only guaranteed at upload time.
5. Run the local checks:

   ```sh
   cabal build all
   cabal test all
   cabal check
   cabal haddock lib:ansiform
   cabal sdist
   ```

6. Run the quality checks described in `docs/quality.md`:

   ```sh
   fourmolu --mode check $(find src examples test -name '*.hs')
   hlint src examples test
   gitleaks git --redact --log-opts="--all"
   gitleaks dir --redact .
   ```

7. Inspect the source distribution:

   ```sh
   tar -tzf dist-newstyle/sdist/ansiform-<version>.tar.gz
   ```

### Uploading to Hackage

`cabal upload` uploads a package candidate by default. A candidate is not visible as a normal package version, so it can be inspected and even deleted before publication.

1. Create a Hackage account and obtain an upload token.
2. Add the token to `~/.cabal/config` as described above. Do not paste the token value into a command or store it in the repository.
3. Build the documentation tarball:

   ```sh
   cabal haddock --haddock-for-hackage
   ```

   The tarball is written to `dist-newstyle/ansiform-<version>-docs.tar.gz`.

4. Upload the source distribution as a candidate:

   ```sh
   cabal upload dist-newstyle/sdist/ansiform-<version>.tar.gz
   ```

5. Upload the documentation candidate:

   ```sh
   cabal upload --documentation dist-newstyle/ansiform-<version>-docs.tar.gz
   ```

6. Inspect the candidate page at `https://hackage.haskell.org/package/ansiform/candidates`. Check the rendered documentation, the dependency bounds and the build report. A candidate that fails verification can be deleted from that page.
7. Stop and wait for explicit approval from the maintainer before publishing. The candidate is reversible; publication is not.
8. After approval, publish the package and its documentation:

   ```sh
   cabal upload --publish dist-newstyle/sdist/ansiform-<version>.tar.gz
   cabal upload --documentation --publish dist-newstyle/ansiform-<version>-docs.tar.gz
   ```

9. Check the public package page, the documentation links and the dependency bounds.

Publishing cannot be undone easily. Never run `--publish` without explicit approval after the candidate review. Use the candidate stage to catch metadata, documentation and dependency problems before publishing.

### GitHub release

1. Confirm that the repository exists and is public. Recreate it only if it is missing.
2. Push the final commit and tag the release:

   ```sh
   git push -u origin master
   git tag -a <version> -m "ansiform <version>"
   git push origin master --tags
   ```

   As in the automated process, use `git tag -s` and `git tag -v <version>` when a signing key is configured.

3. Create a GitHub release from the tag, using the relevant changelog section as the description:

   ```sh
   gh release create <version> --verify-tag --title "ansiform <version>" --notes-file <notes>
   ```

4. Attach the source distribution, the documentation tarball and a `SHA256SUMS` file to the release.
5. Do not add provenance attestations unless the release contains binaries. This project ships source and documentation only.
6. The Hackage badge is already present in the README.

### Verification

Install the published version in a temporary project instead of installing the executables into the user's binary directory:

```sh
mkdir /tmp/ansiform-check
cd /tmp/ansiform-check
cabal repl --build-depends=ansiform==<version>
```

Compile a small expression that imports `Ansiform` and run it. This checks that the published package resolves and that the public API is usable.

## Notes

- The old package name `vis` collided with the Hackage `Vis` package (3D graphics). Do not reuse it.
- The public types no longer use the `Vis` prefix, and the internal builders use the `form` prefix.
- `hie.yaml` is optional editor configuration and is not tracked. Commit it only if the team decides to share it.
- Commits use the GitHub noreply address; maintainer contact uses `dev@tralen.cc`.
- The CI workflow runs GHC 9.2.8 and GHC 9.14.1 with Cabal 3.18.1.0. `macos-15-intel` covers GHC 9.2.8 because the arm64 runner has no bindist for that version. `macos-15` covers GHC 9.14.1 because the SDK on `macos-latest` is too new for its linker.
- The workflows use Node 24 actions. Keep the pinned versions and checksums in `ci.yml` current.
- Formatting, linting and secret scanning are documented in `docs/quality.md`.
