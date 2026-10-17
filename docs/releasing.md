# Releasing

This checklist covers the Hackage and GitHub release of Ansiform. Update it as the release process evolves.

## Current status

- Package: `ansiform`. The name appears to be available on Hackage; check again immediately before uploading.
- Version: 0.7.8.2.
- License: MIT.
- `cabal sdist` produces a complete source distribution with sources, docs, examples, tests, README, ChangeLog and LICENSE.
- Haddock builds with 100% coverage for the public functions and types. The remaining warnings are only about module re-exports.
- CI: `.github/workflows/ci.yml` builds, tests, checks, documents and creates the source distribution with GHC 9.2.8 and GHC 9.14.1.
- GitHub: the repository was deleted to remove personal paths from its history. Recreate it before the next push; the local remote is `git@github.com:Tralen/ansiform.git`.
- `source-repository`, `homepage` and `bug-reports` are set to the GitHub URL.
- The local history has been rewritten and contains no personal paths.
- The roadmap is complete. GitHub publication and the Hackage upload are pending.

## Credentials

Publishing needs two credentials. Local builds, tests, Haddock and `cabal sdist` do not use them.

### Hackage

Export `HACKAGE_TOKEN` with your own secret manager before running the command. Use the token directly on the command line so it is not stored:

```sh
cabal upload --token "$HACKAGE_TOKEN" --publish dist-newstyle/sdist/ansiform-<version>.tar.gz
```

For documentation:

```sh
cabal upload --token "$HACKAGE_TOKEN" --documentation --publish dist-newstyle/sdist/ansiform-<version>-docs.tar.gz
```

Do not add the token or the location of your secret manager to the repository. If a persistent configuration is ever needed, Cabal reads the global `token` key from `~/.cabal/config` or `~/.config/cabal/config`, outside the `repository` stanza. For this project, use the command-line form.

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

1. Recreate the repository as public, if it does not exist.
2. Push the final commit and tag the release:

   ```sh
   git push -u origin master
   git tag -a <version> -m "ansiform <version>"
   git push origin master --tags
   ```

3. Create a GitHub release from the tag, using the relevant ChangeLog section as the description.
4. Add the Hackage badge to the README once the package page exists. The CI and license badges are already present.

## Notes

- The old package name `vis` collided with the Hackage `Vis` package (3D graphics). Do not reuse it.
- The public types no longer use the `Vis` prefix, and the internal builders use the `form` prefix.
- `hie.yaml` is optional editor configuration and is not tracked. Commit it only if the team decides to share it.
- The CI workflow targets GHC 9.14.1 and Cabal 3.18.1.0. Extend the matrix once the supported GHC range is validated.
