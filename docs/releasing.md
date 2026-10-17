# Releasing

This checklist covers the first Hackage and GitHub release of Ansiform. Update it as the release process evolves.

## Current status

- Package: `ansiform`. The name appears to be available on Hackage; check again immediately before uploading.
- Version: 0.7.5.0.
- License: MIT.
- `cabal sdist` produces a complete source distribution with sources, docs, examples, tests, README, CHANGELOG and LICENSE.
- Haddock builds. Function-level documentation coverage is still being improved.
- CI: `.github/workflows/ci.yml` builds, tests, checks, documents and creates the source distribution.
- GitHub remote: `origin` points to https://github.com/Tralen/ansiform.git. The repository is private for now.
- `source-repository`, `homepage` and `bug-reports` are set to the GitHub URL.

## Credentials

Publishing needs two credentials. Local builds, tests, Haddock and `cabal sdist` do not use them.

- `HACKAGE_TOKEN` is the Hackage upload token. Cabal does not read an environment variable automatically; pass it with `--token "$HACKAGE_TOKEN"` or configure it once in the Cabal configuration file. Never commit it or paste it into a command that is logged.
- `GITHUB_TOKEN` is used by GitHub API operations, such as creating a release or a repository with `curl` or `gh`. A normal `git push` uses the remote's SSH key or credential helper, not this variable.

Load the private secrets file in the shell that runs the release commands, and check that the variables are non-empty before uploading. The values must stay out of the repository and out of the documentation.

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

2. Create a GitHub release from the tag, using the relevant CHANGELOG section as the description.
3. Add CI, Hackage and license badges to the README once the URLs exist.

## Notes

- The old package name `vis` collided with the Hackage `Vis` package (3D graphics). Do not reuse it.
- The public types no longer use the `Vis` prefix, and the internal builders use the `form` prefix.
- `hie.yaml` is optional and currently ignored by the user's global Git configuration. Commit it only if the team decides to share the editor configuration.
- The CI workflow targets GHC 9.14.1 and Cabal 3.18.1.0. Extend the matrix once the supported GHC range is validated.
