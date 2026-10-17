# Design notes

These are the original project notes, kept for context. They record ideas that
were considered before the 0.3.0 revival. The current status follows each one.

## Original notes

Biblioteca para controle da formatação do terminal. Usada em todos os
programas de linha de comando.

- Migrar para Text.
- Migrar para Seq.

### Printer

O Printer é similar o Reader Monad, portanto, talvez deva-se considerar usar o
ReaderT em vez do próprio tipo. A questão é que o Printer não tem um parâmetro,
portanto, seria uma especialização.

### Section

O Section deve ser um Monad, pois é preciso passar a posição do cursor para a
próxima section.

### Error

Só há um erro previsto no sistema, que é a má-formação das tabelas. Se for
necessário, elaborar o erro para passá-lo para os níveis superiores.

## Current status

- **Text**: deliberately deferred. CLI content is small, `String` keeps the
  public API simple, and the library only needs a handful of small
  dependencies. Revisit only if large documents or Unicode-heavy processing
  become a requirement; prefer a separate `Text`-based API over a breaking
  change to the core.
- **Seq**: deliberately deferred for the same reason. Lists are adequate for
  the size of menus, tables and articles, and they keep the types simple.
  Revisit only if incremental or very large sequences become a requirement.
- **Printer**: `VisPrinter` is still a specialized configuration reader. The
  public API hides the function behind pure builders, so callers do not depend
  on the representation.
- **Section**: the page runner carries the printed line counts, which play the
  role of the cursor position between sections.
- **Error**: table builders return `Maybe VisTable`. A richer error ADT can be
  introduced later if callers need to distinguish why a table is malformed.
