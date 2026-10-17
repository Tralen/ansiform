# Naming

The package is named `vis`, and the public modules live under the `Vis` namespace.

## Why the name can be confusing

`vis` is a short and generic word. It can be associated with several unrelated projects:

- `vis-network` and its predecessor `vis.js`, JavaScript libraries for graph and network visualization.
- The `vis` text editor, a vi-like editor used from a Unix shell.
- The general abbreviation of words such as visualization and visibility.

The strongest source of confusion is web search: someone looking for `vis-network` may find this Haskell package, and someone looking for this library may find the JavaScript project.

## Why keep the name

- Within Haskell, the package name is the namespace. A Hackage package named `vis` is not the npm package `vis-network`, and Haskell imports use the module name `Vis`, not a global package name.
- The synopsis, category and documentation make the purpose clear: terminal formatting for command-line interfaces.
- Renaming the package and the `Vis` module would be a breaking change for every user and for the project's own history. The ambiguity is mainly at the search level, not at the code level.
- `vis` is already short and memorable, which is valuable for a small library.

## Disambiguation measures

- The README carries a short note stating that this is a terminal formatting library, unrelated to `vis-network`.
- The package synopsis and category describe the domain instead of relying on the name alone.
- The docs consistently describe Vis as a CLI formatting library, not as a visualization library.

## If discoverability becomes a priority

If the project is later published to a broad audience and search confusion becomes a real problem, a more specific name could be considered, for example `vis-cli`, `vis-term` or `ansiform`. That would be a major change: it affects the package name, the module namespace, imports, documentation and links. For now, the costs outweigh the benefit.

## Recommendation

Keep `vis`. The name is not ambiguous inside the Haskell ecosystem, and the synopsis, category, documentation and README note provide enough context for everyone else.
