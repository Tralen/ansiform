# Naming

The package is named `ansiform`, and the public modules live under the `Ansiform` namespace.

## Origin

`ansiform` was suggested by the assistant as a portmanteau of ANSI and form/format. It is not an established term. A Hackage check found no package named `ansiform` or `Ansiform`, so the name appears to be available.

## Why the project was renamed

The project was formerly named `vis`. That name caused two kinds of confusion:

- Hackage already has a package named `Vis` (capital V): Painless 3D graphics, a fork of not-gloss.
- The JavaScript ecosystem has `vis-network` and its predecessor `vis.js`, libraries for graph and network visualization.

The exact lowercase `vis` was not listed on Hackage, but names that differ only in case are a poor idea for discoverability. The rename avoids the case-only distinction and gives the library a distinctive identity.

## What changed

- The package name changed from `vis` to `ansiform`.
- The module namespace changed from `Vis` to `Ansiform`.
- Imports in the demo, tests and user code changed from `import Vis` to `import Ansiform`.
- The demo executable is now `ansiform-demo` and the test suite is `ansiform-test`.
- The license changed from GPL-3.0-only to MIT.

There is no compatibility module named `Vis`. The rename is a breaking change for users of the old package.

## Type names

The public types still carry the `Vis` prefix: `VisItem`, `VisBlock`, `VisPrinter`, `VisPage`, `VisSection`, `VisNumber`, `VisStyle`, `VisColor`, `VisSettings`, `VisConfig`, `VisState`, `VisSample` and so on.

Dropping the prefix is future work. It is a separate breaking change and does not need to happen together with the package rename. Keeping the type names for now preserves some continuity and avoids an unnecessarily large migration.

## Remaining names to avoid confusion

The old name remains in the ChangeLog and in the type prefix. The README and this document explain that `ansiform` is unrelated to the Hackage `Vis` package and to `vis-network`.

## Other candidates

If `ansiform` is not preferred in the future, other distinctive options include `vis-cli`, `vis-term`, `ansiterm` and `termiform`. `vis-cli` and `vis-term` still contain "vis" and are less distinctive than `ansiform`.
