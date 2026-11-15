-- End-to-end smoke test for nvim-openppl, run via:
--   nvim --headless --clean -u NONE -l nvim-openppl/test/headless_test.lua
--
-- Mirrors nvim-phh/nvim-ohh's headless_test.lua discipline.

local root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
vim.opt.runtimepath:append(root .. "/nvim-openppl")

local failures = 0
local function check(label, cond)
  print(("[%s] %s"):format(cond and "ok" or "FAIL", label))
  if not cond then failures = failures + 1 end
end

dofile(root .. "/nvim-openppl/ftdetect/openppl.lua")

local openppl = require("openppl")
openppl.setup({
  server_path = root .. "/openppl-ls/build/openppl-ls",
  registry_path = root .. "/openppl-data/registry",
})

check("setup() recorded state", openppl._state ~= nil)

local function open_and_wait(path)
  vim.cmd.edit(path)
  local bufnr = vim.api.nvim_get_current_buf()
  check(path .. ": filetype detected as openppl", vim.bo[bufnr].filetype == "openppl")

  local got_diagnostics = false
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    buffer = bufnr,
    once = true,
    callback = function() got_diagnostics = true end,
  })

  local attached = vim.wait(5000, function()
    return #vim.lsp.get_clients({ bufnr = bufnr, name = "openppl-ls" }) > 0
  end, 50)
  check(path .. ": openppl-ls client attached", attached)

  vim.wait(3000, function() return got_diagnostics end, 50)

  return bufnr
end

local valid_files = vim.fn.glob(root .. "/openppl-data/corpus/valid/*.ohf", false, true)
local invalid_files = vim.fn.glob(root .. "/openppl-data/corpus/invalid/*.ohf", false, true)

for _, path in ipairs(valid_files) do
  local bufnr = open_and_wait(path)
  local diags = vim.diagnostic.get(bufnr)
  check(vim.fn.fnamemodify(path, ":t") .. ": zero diagnostics", #diags == 0)

  local highlighter_active = vim.treesitter.highlighter.active[bufnr] ~= nil
  check(vim.fn.fnamemodify(path, ":t") .. ": tree-sitter highlighter active", highlighter_active)
end

for _, path in ipairs(invalid_files) do
  local bufnr = open_and_wait(path)
  local diags = vim.diagnostic.get(bufnr)
  check(vim.fn.fnamemodify(path, ":t") .. ": at least one diagnostic", #diags >= 1)
end

-- Hover on structure-example.ohf's "hand$AA" (0-indexed line 3: header,
-- two comment lines, then the WHEN hand$AA rule).
do
  local path = root .. "/openppl-data/corpus/valid/structure-example.ohf"
  local bufnr = open_and_wait(path)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "openppl-ls" })
  if #clients > 0 then
    local result = clients[1]:request_sync(
      "textDocument/hover",
      {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        position = { line = 3, character = 12 },
      },
      5000,
      bufnr
    )
    local value = result and result.result and result.result.contents and result.result.contents.value
    check("hover on hand$AA returns content", value ~= nil)
    check("hover on hand$AA mentions pocket pair", value ~= nil and value:lower():find("pair") ~= nil)
  else
    check("hover on hand$AA returns content", false)
  end
end

print()
if failures > 0 then
  print(("%d FAILURE(S)"):format(failures))
  vim.cmd("cquit 1")
else
  print("All checks passed.")
  vim.cmd("qa")
end
