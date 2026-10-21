# Releasing

This checklist covers the Hackage and GitHub release of Ansiform. Update it as the release process evolves.

## Current status

- Package: `ansiform`. The name is already registered on Hackage.
- Version: 1.0.0.
- License: MIT.
- `cabal sdist` produces a complete source distribution with sources, docs, examples, tests, README, ChangeLog and LICENSE.
- Haddock builds with 100% coverage for the public functions and types. The remaining warnings are only about module re-exports.
- CI: `.github/workflows/ci.yml` builds, tests, checks, documents and creates the source distribution on Linux, macOS and Windows, with GHC 9.2.8 and GHC 9.14.1. macOS uses `macos-15` and only GHC 9.14.1: GHC 9.2.8 has no aarch64-darwin bindist, and the SDK on `macos-latest` is too new for the GHC 9.14.1 linker.
- GitHub: public at <https://github.com/Tralen/ansiform>; the local remote is `git@github.com:Tralen/ansiform.git`.
- `source-repository`, `homepage` and `bug-reports` are set to the GitHub URL.
- The history has been rewritten and contains no personal paths.
- Tag `1.0.0` and its GitHub release are published at <https://github.com/Tralen/ansiform/releases/tag/1.0.0>.
- Hackage: 1.0.0 is published at <https://hackage.haskell.org/package/ansiform-1.0.0>, with documentation uploaded.
- The 1.0.0 release marks the library stable and draws every prefilled field when a form opens. It includes the editable form fields, `Ansiform.Line`, `readKeyPress`, the lone-Escape fix and the platform documentation from 0.8.0 through 0.9.0.6.

## Credentials

Publishing needs two credentials. Local builds, tests, Haddock and `cabal sdist` do not use them.

### Hackage

Export `HACKAGE_TOKEN` with your own secret manager before running the command. Use the token directly on the command line so it is not stored:

```sh
cabal upload --token "$HACKAGE_TOKEN" dist-newstyle/sdist/ansiform-<version>.tar.gz
```

For documentation:

```sh
cabal upload --token "$HACKAGE_TOKEN" --documentation dist-newstyle/ansiform-<version>-docs.tar.gz
```

Do not add the token or the location of your secret manager to the repository. If a persistent configuration is ever needed, Cabal reads the global `token` key from `~/.cabal/config` or `~/.config/cabal/config`, outside the `repository` stanza. For this project, use the command-line form.

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

The repository must be public for the package links and badges to work. Pushes still require a key belonging to an account with write access. `GITHUB_TOKEN` is not used automatically by `git push`; it is only for the GitHub API or `gh`.

Never print the values of the tokens or commit the location of your secrets.

## Before the first release

1. Configure an SSH key for GitHub and confirm write access to the repository.
2. Verify the remote:

   ```sh
   git remote -v
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

6. Inspect the source distribution:

   ```sh
   tar -tzf dist-newstyle/sdist/ansiform-<version>.tar.gz
   ```

## Uploading to Hackage

`cabal upload` uploads a **package candidate** by default. A candidate is not visible as a normal package version, so it can be inspected and even deleted before publication.

1. Create a Hackage account and obtain an upload token.
2. Configure the token, preferably through the interactive prompt or the Cabal config file. Avoid putting the token directly in shell history.
3. Build the documentation tarball:

   ```sh
   cabal haddock --haddock-for-hackage
   ```

   The tarball is written to `dist-newstyle/ansiform-<version>-docs.tar.gz`.

4. Upload the source distribution as a candidate:

   ```sh
   cabal upload --token "$HACKAGE_TOKEN" dist-newstyle/sdist/ansiform-<version>.tar.gz
   ```

5. Upload the documentation candidate:

   ```sh
   cabal upload --token "$HACKAGE_TOKEN" --documentation dist-newstyle/ansiform-<version>-docs.tar.gz
   ```

6. Inspect the candidate page at `https://hackage.haskell.org/package/ansiform/candidates`. Check the rendered documentation, the dependency bounds and the build report. A candidate that fails verification can be deleted from that page.
7. Stop and wait for explicit approval from the maintainer before publishing. The candidate is reversible; publication is not.
8. After approval, publish the package and its documentation:

   ```sh
   cabal upload --token "$HACKAGE_TOKEN" --publish dist-newstyle/sdist/ansiform-<version>.tar.gz
   cabal upload --token "$HACKAGE_TOKEN" --documentation --publish dist-newstyle/ansiform-<version>-docs.tar.gz
   ```

9. Check the public package page, the documentation links and the dependency bounds.

Publishing cannot be undone easily. Never run `--publish` without explicit approval after the candidate review. Use the candidate stage to catch metadata, documentation and dependency problems before publishing.

## GitHub release

1. Confirm that the repository exists and is public. Recreate it only if it is missing.
2. Push the final commit and tag the release:

   ```sh
   git push -u origin master
   git tag -a <version> -m "ansiform <version>"
   git push origin master --tags
   ```

3. Create a GitHub release from the tag, using the relevant ChangeLog section as the description.
4. The Hackage badge is already present in the README.

## Notes

- The old package name `vis` collided with the Hackage `Vis` package (3D graphics). Do not reuse it.
- The public types no longer use the `Vis` prefix, and the internal builders use the `form` prefix.
- `hie.yaml` is optional editor configuration and is not tracked. Commit it only if the team decides to share it.
- Commits use the GitHub noreply address; maintainer contact uses `dev@tralen.cc`.
- The CI workflow runs GHC 9.2.8 and GHC 9.14.1 with Cabal 3.18.1.0 on Ubuntu, Windows and `macos-15`. Keep the macOS pin until a newer GHC supports the `macos-latest` SDK.
