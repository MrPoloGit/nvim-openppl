-- Neovim support for OpenPPL (.ohf).
--
-- Same shape as nvim-phh/nvim-ohh: registers the one grammar every other
-- editor in this project uses (tree-sitter-openppl's compiled grammar + its
-- canonical queries/) for highlighting, and openppl-ls itself for
-- diagnostics/hover/completion via Neovim's built-in LSP client.
--
-- Now has a registry_path setting, same as nvim-phh/nvim-ohh.
-- openppl-ls's first release took no registry argument at all, but now
-- loads openppl-data/registry/symbols.json, so setup() refuses to start without
-- registry_path, same "never approximate silently" rule those two
-- plugins already followed.
--
-- By design, this module does nothing on require(); call M.setup() from
-- your config.

local M = {}

local function plugin_root()
  local source = debug.getinfo(1, "S").source
  local this_file = source:sub(2)
  return vim.fn.fnamemodify(this_file, ":h:h:h")
end

local function read_file(path)
  local fd = io.open(path, "r")
  if not fd then return nil end
  local content = fd:read("*a")
  fd:close()
  return content
end

local function load_queries(lang, grammar_path, names)
  for _, name in ipairs(names) do
    local path = grammar_path .. "/queries/" .. name .. ".scm"
    local content = read_file(path)
    if content then
      local ok, err = pcall(vim.treesitter.query.set, lang, name, content)
      if not ok then
        vim.notify(
          ("openppl: failed to register %s query for %s: %s"):format(name, lang, err),
          vim.log.levels.WARN
        )
      end
    else
      vim.notify(
        ("openppl: query file not found: %s (grammar_path may be wrong)"):format(path),
        vim.log.levels.WARN
      )
    end
  end
end

M._state = nil

function M.setup(opts)
  opts = opts or {}
  local root = plugin_root()

  local config = {
    server_path = opts.server_path or "openppl-ls",
    registry_path = opts.registry_path,
    grammar_path = opts.grammar_path or vim.fn.fnamemodify(root .. "/../tree-sitter-openppl", ":p"),
  }
  M._state = config

  if not config.registry_path or config.registry_path == "" then
    vim.notify(
      "openppl: setup() needs registry_path (openppl-ls has no built-in default)",
      vim.log.levels.ERROR
    )
    return
  end

  local ok_openppl, err_openppl = pcall(vim.treesitter.language.add, "openppl", {
    path = root .. "/parser/openppl.so",
  })
  if not ok_openppl then
    vim.notify("openppl: failed to load parser/openppl.so: " .. tostring(err_openppl), vim.log.levels.ERROR)
  end

  if ok_openppl then
    -- Deliberately NOT "outline", same omission nvim-phh/nvim-ohh make:
    -- Neovim has no built-in consumer of a tree-sitter "outline" query.
    load_queries("openppl", config.grammar_path, { "highlights", "folds", "indents" })
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "openppl",
    group = vim.api.nvim_create_augroup("openppl_treesitter", { clear = true }),
    callback = function(args)
      if ok_openppl then
        pcall(vim.treesitter.start, args.buf, "openppl")
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "openppl",
    group = vim.api.nvim_create_augroup("openppl_lsp", { clear = true }),
    callback = function(args)
      vim.lsp.start({
        name = "openppl-ls",
        cmd = { config.server_path, config.registry_path },
        root_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":p:h"),
      })
    end,
  })
end

return M
