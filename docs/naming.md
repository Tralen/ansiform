# Naming

The package is named `ansiform`, and the public modules live under the `Ansiform` namespace.

## Origin

`ansiform` is a portmanteau of ANSI and form/format. It is not an established term.

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

There is no compatibility module named `Vis`. The rename is a breaking change for users of the old package, introduced in the 0.4.0 release.

## Public types

The 0.5.0 release removed the `Vis` prefix from the public types. The public API now uses `Item`, `Block`, `Group`, `Table`, `Paragraph`, `Article`, `Rule`, `Number`, `Width`, `Padding`, `Offset`, `Color`, `Format`, `Style`, `Printer`, `Section`, `Page`, `Settings`, `Config`, `State` and `Sample`.

## Builder names

The 0.6.0 release removed the `vis` prefix from the internal builder helpers. They now use the `form` prefix: `formItem`, `formBlock`, `formGroup`, `formTable`, `formRule`, `formPrinter`, `formSection`, `formPage`, `formSettings`, `formConfig`, `formState`, `formNumber`, `formColor`, `formFormat` and `formStyle`. The low-level style helpers use descriptive names: `applyStyle`, `resetStyle`, `styleCommands`, `colorCommands`, `formatCommands`, `setBackground` and `swapBackground`. The public `visNumber` is now `formNumber`.

The public builders remain unprefixed (`item`, `block`, `groupSimple`, `tableBlocks`, `printerLeft`, `section`, `page`, etc.).

## Remaining names to avoid confusion

The old package name remains in the changelog for historical context. The public API no longer uses the `Vis` prefix, nor does it export the `vis` builder prefix. The README explains that `ansiform` is unrelated to the Hackage `Vis` package and to `vis-network`.
