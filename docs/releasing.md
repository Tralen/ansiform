# Releasing

This checklist covers the first Hackage and GitHub release of Ansiform. Update it as the release process evolves.

## Current status

- Package: `ansiform`. The name appears to be available on Hackage; check again immediately before uploading.
- Version: 0.7.0.
- License: MIT.
- `cabal sdist` produces a complete source distribution with sources, docs, examples, tests, README, CHANGELOG and LICENSE.
- Haddock builds. Function-level documentation coverage is still being improved.
- CI: `.github/workflows/ci.yml` builds, tests, checks, documents and creates the source distribution.
- GitHub remote: not configured yet.
- `source-repository`, `homepage` and `bug-reports` are not set because the repository URL is not known yet.

## Before the first release

1. Create the GitHub repository.
2. Add the remote:

   ```sh
   git remote add origin https://github.com/<user>/ansiform.git
   git push -u origin master
   ```

3. Add the repository metadata to `ansiform.cabal`:

   ```cabal
   homepage:       https://github.com/<user>/ansiform
   bug-reports:    https://github.com/<user>/ansiform/issues
   source-repository head
     type:     git
     location: https://github.com/<user>/ansiform.git
   ```

   The `source-repository` section removes the `no-repository` warning from `cabal check`.

4. Optionally remove the old `.hg` directory if the project is now Git-only.
5. Check the package name on Hackage again. Names are only guaranteed at upload time.
6. Run the local checks:

   ```sh
   cabal build all
   cabal test all
   cabal check
   cabal haddock lib:ansiform
   cabal sdist
   ```

7. Inspect the source distribution:

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
   cabal upload --token <token> --publish dist-newstyle/sdist/ansiform-<version>.tar.gz
   ```

4. Upload the documentation for the published package:

   ```sh
   cabal upload --token <token> --documentation --publish dist-newstyle/sdist/ansiform-<version>-docs.tar.gz
   ```

5. Check the package page, the documentation links and the dependency bounds.

## GitHub release

1. Push the final commit and tag the release:

   ```sh
   git tag -a <version> -m "ansiform <version>"
   git push origin master --tags
   ```

2. Create a GitHub release from the tag, using the relevant CHANGELOG section as the description.
3. Add CI, Hackage and license badges to the README once the URLs exist.

## Notes

- The old package name `vis` collided with the Hackage `Vis` package (3D graphics). Do not reuse it.
- The public types no longer use the `Vis` prefix, and the internal builders use the `form` prefix.
- `hie.yaml` is optional and currently ignored by the user's global Git configuration. Commit it only if the team decides to share the editor configuration.
- The CI workflow targets GHC 9.14.1 and Cabal 3.18.1.0. Extend the matrix once the supported GHC range is validated.
