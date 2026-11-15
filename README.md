# nvim-openppl

Neovim support for OpenPPL (.ohf).

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
