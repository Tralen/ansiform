# Design notes

These are the original project notes, kept for context. They record ideas that were considered before the 0.3.0 revival. The current status follows each one.

## Original notes

Biblioteca para controle da formatação do terminal. Usada em todos os programas de linha de comando.

- Migrar para Text.
- Migrar para Seq.

### Printer

O Printer é similar o Reader Monad, portanto, talvez deva-se considerar usar o ReaderT em vez do próprio tipo. A questão é que o Printer não tem um parâmetro, portanto, seria uma especialização.

### Section

O Section deve ser um Monad, pois é preciso passar a posição do cursor para a próxima section.

### Error

Só há um erro previsto no sistema, que é a má-formação das tabelas. Se for necessário, elaborar o erro para passá-lo para os níveis superiores.

## Current status

- **Text**: deliberately deferred. CLI content is small, `String` keeps the public API simple, and the library only needs a handful of small dependencies. Revisit only if large documents or Unicode-heavy processing become a requirement; prefer a separate `Text`-based API over a breaking change to the core.
- **Seq**: deliberately deferred for the same reason. Lists are adequate for the size of menus, tables and articles, and they keep the types simple. Revisit only if incremental or very large sequences become a requirement.
- **Printer**: `VisPrinter` is already a specialized `ReaderT VisConfig IO` plus a line count. The representation stays hidden because exposing a monadic builder would leak IO and let callers bypass section and page bookkeeping. A separate `Vis.Monad` layer can be added later if a concrete need appears; the pure builders should remain the primary API.
- **Section**: cursor position and line counts are threaded explicitly by `runSection`/`runPage` and stored in `VisState`. A `State` monad would duplicate that mechanism and make simple sections more verbose, so it is deliberately deferred until there is a real use case. The existing `replace`/`amend` lifecycle already covers the practical need to preserve rows.
- **Error**: table builders return `Maybe VisTable`. A richer error ADT can be introduced later if callers need to distinguish why a table is malformed.
