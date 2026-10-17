# Releasing

This checklist covers the first Hackage and GitHub release of Ansiform. Update it as the release process evolves.

## Current status

- Package: `ansiform`. The name appears to be available on Hackage; check again immediately before uploading.
- Version: 0.7.7.0.
- License: MIT.
- `cabal sdist` produces a complete source distribution with sources, docs, examples, tests, README, ChangeLog and LICENSE.
- Haddock builds with 100% coverage for the public functions and types. The remaining warnings are only about module re-exports.
- CI: `.github/workflows/ci.yml` builds, tests, checks, documents and creates the source distribution with GHC 9.2.8 and GHC 9.14.1.
- GitHub remote: `origin` uses SSH (`git@github.com:Tralen/ansiform.git`). The repository is private for now.
- `source-repository`, `homepage` and `bug-reports` are set to the GitHub URL.
- Publication is deferred until the roadmap is complete.

## Credentials

Publishing needs two credentials. Local builds, tests, Haddock and `cabal sdist` do not use them.

### Hackage

Use the token directly on the command line so it is not stored:

```sh
cabal upload --token "$HACKAGE_TOKEN" --publish dist-newstyle/sdist/ansiform-<version>.tar.gz
```

For documentation:

```sh
cabal upload --token "$HACKAGE_TOKEN" --documentation --publish dist-newstyle/sdist/ansiform-<version>-docs.tar.gz
```

Do not add the token to the repository. If a persistent configuration is ever needed, Cabal reads the global `token` key from `~/.cabal/config` or `~/.config/cabal/config`, outside the `repository` stanza. For this project, use the command-line form.

### GitHub

This project uses SSH for pushes. Configure a key for your GitHub account.

1. Add the public key to GitHub under **Settings > SSH and GPG keys**:

   ```sh
   cat ~/.ssh/id_ed25519.pub
   ```

2. Test the connection:

   ```sh
   ssh -T git@github.com
   ```

3. Verify that the remote uses SSH:

   ```sh
   git remote -v
   git remote set-url origin git@github.com:Tralen/ansiform.git
   ```

The repository is private, so the key must belong to an account with access. `GITHUB_TOKEN` is not used automatically by `git push`; it is only for the GitHub API or `gh`.

Never print the values of the tokens or commit the secrets file.

## Before the first release

1. Authorize the SSH public key on GitHub and confirm access to the private repository.
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
