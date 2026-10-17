# Releasing

This checklist covers the first Hackage and GitHub release of Ansiform. Update it as the release process evolves.

## Current status

- Package: `ansiform`. The name appears to be available on Hackage; check again immediately before uploading.
- Version: 0.7.5.2.
- License: MIT.
- `cabal sdist` produces a complete source distribution with sources, docs, examples, tests, README, ChangeLog and LICENSE.
- Haddock builds with 100% coverage for the public functions and types. The remaining warnings are only about module re-exports.
- CI: `.github/workflows/ci.yml` builds, tests, checks, documents and creates the source distribution.
- GitHub remote: `origin` points to https://github.com/Tralen/ansiform.git. The repository is private for now.
- `source-repository`, `homepage` and `bug-reports` are set to the GitHub URL.

## Credentials

Publishing needs two credentials. Local builds, tests, Haddock and `cabal sdist` do not use them.

### Hackage

Cabal reads the global keys `token`, `username`, `password` and `password-command` from the user config. Depending on the installation, the file is `~/.cabal/config` (legacy layout) or `~/.config/cabal/config` (XDG layout). Use the file Cabal already uses; `cabal user-config` refers to the XDG path.

1. Store the token in the Cabal config for repeated releases. `token` is a global key, so it must be at the top level, not inside the `repository` stanza:

   ```cabal
   token: <hackage-token>

   repository hackage.haskell.org
     url: http://hackage.haskell.org/
   ```

   The `repository` stanza configures the server; it is not where the upload token belongs.

2. Pass it per command after loading your secrets file:

   ```sh
   cabal upload --token "$HACKAGE_TOKEN" --publish dist-newstyle/sdist/ansiform-<version>.tar.gz
   ```

3. Use a command that prints the token on demand:

   ```sh
   cabal upload --password-command 'cat /path/to/hackage-token' --publish <tarball>
   ```

Never put the token directly in shell history or commit the file that contains it.

### GitHub

`GITHUB_TOKEN` is used by the GitHub API and by `gh`. It is not used automatically by `git push`. Choose one of these:

- **SSH**, recommended:

  ```sh
  git remote set-url origin git@github.com:Tralen/ansiform.git
  ```

  The corresponding public key must be registered on GitHub.
- **`gh`**, if installed:

  ```sh
  gh auth login
  ```

  `gh` configures the git credential helper. It is not installed in the current environment.
- **HTTPS credential helper**: configure a helper that reads the token from your secret store. Avoid `credential.helper store`, which saves the token in plain text.

The private secrets file is not inherited by non-interactive shells. Load it in the shell that runs the release commands, for example with `source`, or configure the credentials persistently.

Never print the values of the tokens or commit the secrets file.

## Before the first release

1. Confirm access to the GitHub repository and decide when it becomes public.
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

1. Create a Hackage account and obtain an upload token.
2. Configure the token, preferably through the interactive prompt or the Cabal config file. Avoid putting the token directly in shell history.
3. Upload the source distribution:

   ```sh
   cabal upload --publish dist-newstyle/sdist/ansiform-<version>.tar.gz
   ```

   If the token is not configured, pass it explicitly:

   ```sh
   cabal upload --token "$HACKAGE_TOKEN" --publish dist-newstyle/sdist/ansiform-<version>.tar.gz
   ```

4. Upload the documentation for the published package:

   ```sh
   cabal upload --token "$HACKAGE_TOKEN" --documentation --publish dist-newstyle/sdist/ansiform-<version>-docs.tar.gz
   ```

5. Check the package page, the documentation links and the dependency bounds.

## GitHub release

1. Push the final commit and tag the release:

   ```sh
   git tag -a <version> -m "ansiform <version>"
   git push origin master --tags
   ```

2. Create a GitHub release from the tag, using the relevant ChangeLog section as the description.
3. Add CI, Hackage and license badges to the README once the URLs exist.

## Notes

- The old package name `vis` collided with the Hackage `Vis` package (3D graphics). Do not reuse it.
- The public types no longer use the `Vis` prefix, and the internal builders use the `form` prefix.
- `hie.yaml` is optional and currently ignored by the user's global Git configuration. Commit it only if the team decides to share the editor configuration.
- The CI workflow targets GHC 9.14.1 and Cabal 3.18.1.0. Extend the matrix once the supported GHC range is validated.
