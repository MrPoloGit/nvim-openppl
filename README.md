# nvim-openppl

Neovim support for OpenPPL (.ohf). Same shape as `nvim-phh`/
`nvim-ohh`: uses `tree-sitter-openppl`'s grammar and canonical `queries/`
for highlighting, and `openppl-ls` itself for diagnostics/hover/
completion via Neovim's built-in LSP client.

## Now has a registry setting, same as nvim-phh/nvim-ohh

`openppl-ls`'s first release took no registry argument at all
; it now loads
`openppl-data/registry/symbols.json`, so `setup()` requires `registry_path`,
same "never approximate silently" rule `nvim-phh`/`nvim-ohh` already
follow.

## Setup

```lua
require("openppl").setup({
  server_path = "/absolute/path/to/openppl-ls/build/openppl-ls", -- default: "openppl-ls" on PATH
  registry_path = "/absolute/path/to/openppl-data/registry", -- required, no default
  -- grammar_path defaults to the sibling tree-sitter-openppl checkout.
})
```

Add this plugin's directory to Neovim's runtime path however your plugin
manager expects, then call `setup()` from your config.

**Not listed anywhere.** This repo is pushed to
`github.com/MrPoloGit/nvim-openppl`, usable today by any plugin manager
that takes a plain git URL, but it isn't listed in awesome-neovim or
any other curated index, nothing has been submitted anywhere.

## Platform note: the bundled grammar is macOS arm64 only

`parser/openppl.so` is a pre-compiled Mach-O arm64 dynamic library (`file
parser/openppl.so` confirms this), built from `../tree-sitter-openppl`'s
generated `src/parser.c`. On any other platform (Linux, Windows, or
macOS on Intel), `setup()` will fail to load it, and you need to rebuild
it yourself, which only needs the `tree-sitter` CLI (`npm install -g
tree-sitter-cli`, or see its own install docs) and a C compiler:

```sh
tree-sitter build ../tree-sitter-openppl -o parser/openppl.so
```

Despite the `.so` extension (kept for Neovim's own convention, which
doesn't care whether the file is actually an ELF `.so`, a Mach-O
`.dylib`, or (after this exact command, run on Windows) a PE `.dll`),
`tree-sitter build` always produces the right native format for whatever
platform it runs on, confirmed by running it on this machine and getting
back the same Mach-O arm64 library already bundled.

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

drives the real plugin against the real corpus (`../openppl-data/corpus/`).
**All checks pass on the first real run**, same clean result
`nvim-phh`/`nvim-ohh` got, for the same reason (Neovim's built-in
tree-sitter/LSP client needs nothing editor-specific once the grammar
and server exist). Also checks hover on `hand$AA` returns the pocket-pair
description through the real LSP client. `:checkhealth openppl` was
separately run and confirmed all-green.
