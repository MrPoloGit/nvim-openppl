# nvim-openppl

Neovim support for OpenPPL (.ohf). Same shape as `nvim-phh`/
`nvim-ohh`: uses `tree-sitter-openppl`'s grammar and canonical `queries/`
for highlighting, and `openppl-ls` itself for diagnostics/hover/
completion via Neovim's built-in LSP client.

## Now has a registry setting, same as nvim-phh/nvim-ohh

`openppl-ls`'s first release took no registry argument at all
; it now loads
`openppl/registry/symbols.json`, so `setup()` requires `registry_path`,
same "never approximate silently" rule `nvim-phh`/`nvim-ohh` already
follow.

## Setup

```lua
require("openppl").setup({
  server_path = "/absolute/path/to/openppl-ls/build/openppl-ls", -- default: "openppl-ls" on PATH
  registry_path = "/absolute/path/to/openppl/registry", -- required, no default
  -- grammar_path defaults to the sibling tree-sitter-openppl checkout.
})
```

## What's implemented

- **Filetype detection** (`ftdetect/openppl.lua`): `.ohf` → `openppl`.
- **Tree-sitter highlighting**: pre-compiled `parser/openppl.so` (built
  from `../tree-sitter-openppl`'s generated `src/parser.c`, same
  one-`clang`-call build as the other grammars in this project).
  `setup()` loads `highlights`/`folds`/`indents` (not `outline`, same
  omission `nvim-phh`/`nvim-ohh` make, since Neovim has no built-in
  consumer of that query type).
- **LSP**: `vim.lsp.start` on every `openppl` buffer, via Neovim's
  built-in client.
- **`:checkhealth openppl`**: reports whether `openppl-ls` is reachable,
  the registry is present, the compiled grammar exists, and its query
  files are reachable.

## How this was verified

`test/headless_test.lua`, run via:

```sh
nvim --headless --clean -u NONE -l nvim-openppl/test/headless_test.lua
```

drives the real plugin against the real corpus (`../openppl/corpus/`).
**All checks pass on the first real run**, same clean result
`nvim-phh`/`nvim-ohh` got, for the same reason (Neovim's built-in
tree-sitter/LSP client needs nothing editor-specific once the grammar
and server exist). Also checks hover on `hand$AA` returns the pocket-pair
description through the real LSP client. `:checkhealth openppl` was
separately run and confirmed all-green.
