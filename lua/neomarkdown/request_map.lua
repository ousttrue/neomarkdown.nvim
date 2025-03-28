local RequestMap = {}
RequestMap.__index = RequestMap

---@alias neomarkdown.RootType 'docusaurus'|'git'|'fallback'

---@param root_dir string
---@param root_type neomarkdown.RootType
---@return table<string, neomarkdown.Method> request_map
function RequestMap.make_request_map(root_dir, root_type)
  local ws = require("neomarkdown.Workspace").new(root_dir)

  local request_map = {}

  request_map[vim.lsp.protocol.Methods.textDocument_definition] = function(...)
    return ws:lsp_definition(...)
  end

  return request_map
end

return RequestMap
