-- :checkhealth openppl, same role as nvim-phh/nvim-ohh's health.lua.
-- Now includes a registry check, same as those two, openppl-ls's first
-- release had no registry at all.

local M = {}

local function file_exists(path)
  local fd = io.open(path, "r")
  if fd then
    fd:close()
    return true
  end
  return false
end

local function dir_exists(path)
  return vim.fn.isdirectory(path) == 1
end

function M.check()
  local health = vim.health or require("health")
  health.start("openppl")

  local openppl = require("openppl")
  local state = openppl._state

  if not state then
    health.warn('require("openppl").setup() has not been called yet, nothing else can be checked.')
    return
  end

  if vim.fn.executable(state.server_path) == 1 then
    health.ok(("openppl-ls found: %s"):format(state.server_path))
  else
    health.error(
      ("openppl-ls not found or not executable: %s"):format(state.server_path),
      { "Set openppl.server_path to an absolute path, or add openppl-ls to your PATH." }
    )
  end

  if dir_exists(state.registry_path) and file_exists(state.registry_path .. "/symbols.json") then
    health.ok(("registry found: %s"):format(state.registry_path))
  else
    health.error(("registry at %s is missing symbols.json"):format(tostring(state.registry_path)))
  end

  local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
  local so_path = root .. "/parser/openppl.so"
  if file_exists(so_path) then
    health.ok(("openppl.so present: %s"):format(so_path))
  else
    health.error(("openppl.so not found: %s (rebuild with the sibling grammar repo)"):format(so_path))
  end

  local missing = {}
  for _, name in ipairs({ "highlights", "folds", "indents" }) do
    if not file_exists(state.grammar_path .. "/queries/" .. name .. ".scm") then
      table.insert(missing, name)
    end
  end
  if #missing == 0 then
    health.ok(("openppl queries found at %s"):format(state.grammar_path))
  else
    health.warn(
      ("openppl: missing query files at %s: %s"):format(state.grammar_path, table.concat(missing, ", "))
    )
  end
end

return M
