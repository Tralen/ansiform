# Naming

The package is currently named `vis`, and the public modules live under the `Vis` namespace.

## Current situation

- Hackage already has a package named `Vis` (capital V): Painless 3D graphics, a fork of not-gloss.
- The exact lowercase `vis` is not currently listed on Hackage, but names that differ only in case are a poor idea for discoverability.
- The JavaScript ecosystem also has `vis-network` and its predecessor `vis.js`, libraries for graph and network visualization.

The name is therefore risky for a public release, even though the Haskell package name and the JavaScript package name live in different ecosystems.

## Recommendation

If the library is only used locally, the current name is acceptable. If it is going to be published on Hackage, rename it before the first release. The package name and the module namespace change together, so renaming later would be a breaking change for users.

## ansiform

`ansiform` was suggested by the assistant as a portmanteau of ANSI and form/format. It is not an established term. A Hackage check found no package named `ansiform` or `Ansiform`, so it appears to be available.

Advantages:

- It describes the domain: ANSI terminal formatting.
- It is distinctive and unlikely to collide with the JavaScript visualization ecosystem or the Hackage `Vis` 3D graphics package.
- It avoids the case-only distinction between `vis` and `Vis`.

The rename would affect:

- the package name (`vis` to `ansiform`);
- the module namespace (`Vis` to `Ansiform`);
- imports in the demo, tests and user code;
- documentation, links and the ChangeLog.

Because the API is otherwise unchanged, the rename can be done as a single major release. It is best done before publishing.

## Other candidates

If `ansiform` is not preferred, other distinctive options to evaluate include `vis-cli`, `vis-term`, `ansiterm` and `termiform`. `vis-cli` and `vis-term` still contain "vis" and are less distinctive than `ansiform`.

## What was already done

- The README carries a note distinguishing this library from `vis-network` and the Hackage `Vis` package.
- This document records the rationale and the options.
