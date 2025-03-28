local Logger = require "neomarkdown.Logger"
local request_map = require "neomarkdown.request_map"

local NAME = "neomrkdown"
Logger.name = NAME

---@return string? root_dir
---@return neomarkdown.RootType?
local function get_root_dir()
  local root_dir = vim.fs.root(0, "sidebars.ts")
  if root_dir then
    return root_dir, "docusaurus"
  end

  -- fallback git
  root_dir = vim.fs.root(0, ".git")
  if root_dir then
    return root_dir, "git"
  end

  return "/", "fallback"
end

---@type lsp.ServerCapabilities
local LSP_CAPABILITIES = {
  -- completionProvider = {
  --   -- triggerCharacters = { "▽" },
  -- },
  -- textDocumentSync = {
  --   change = 1, -- prompt LSP client to send full document text on didOpen and didChange
  --   openClose = true,
  --   save = { includeText = true },
  -- },
  -- hoverProvider = true,
  definitionProvider = true,
}

---@alias neomarkdown.Method fun(params: table?)[lsp.ResponseError?, any]

---@class neomarkdown.LanguageServer
---@field logger neomarkdown.Logger
---@field dispatchers vim.lsp.rpc.Dispatchers
---@field message_id integer
---@field stopped boolean
---@field request_map table<string, neomarkdown.Method>
local LanguageServer = {}
LanguageServer.__index = LanguageServer
LanguageServer.server_name = NAME
LanguageServer.capabilities = LSP_CAPABILITIES

---@param logger neomarkdown.Logger
---@param dispatchers vim.lsp.rpc.Dispatchers
---@params request_map table<string, neomarkdown.Method>
---@return neomarkdown.LanguageServer
function LanguageServer.new(logger, dispatchers, request_map)
  local self = setmetatable({
    logger = logger,
    dispatchers = dispatchers,
    message_id = 1,
    stopped = false,
    request_map = request_map,
  }, LanguageServer)
  return self
end

function LanguageServer:stop()
  self.stopped = true
end

--@param root_dir string
function LanguageServer.launch()
  local logger = Logger.new()
  local root_dir, root_type = get_root_dir()
  if not root_dir or not root_type then
    logger:error "no root_dir"
    return
  end

  if root_type == "docusaurus" then
    root_dir = vim.fs.joinpath(root_dir, "docs")
  end
  local config = {
    name = NAME,
    root_dir = root_dir,
    ---@param dispatchers vim.lsp.rpc.Dispatchers
    ---@return vim.lsp.rpc.PublicClient
    cmd = function(dispatchers)
      local map = request_map.make_request_map(root_dir, root_type)
      local server = LanguageServer.new(logger, dispatchers, map)
      return {
        request = function(...)
          server:request(...)
        end,
        notify = function(...)
          server:notify(...)
        end,
        is_closing = function()
          return server.stopped
        end,
        terminate = function()
          server:stop()
        end,
      }
    end,
  }
  local id = vim.lsp.start(config)
  if not id then
    logger:error(string.format("failed to start client with config: %s", vim.inspect(config)))
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local did_attach = vim.lsp.buf_is_attached(bufnr, id) or vim.lsp.buf_attach_client(bufnr, id)
  if not did_attach then
    logger:warn(string.format("failed to attach buffer %d", bufnr))
    return
  end
end

---@param method vim.lsp.protocol.Method|string LSP method name.
---@param params table? LSP request params.
---@return lsp.ResponseError? err
---@return any? result
function LanguageServer:_handle(method, params)
  self.message_id = self.message_id + 1
  if method == vim.lsp.protocol.Methods.initialize then
    return nil, { capabilities = LanguageServer.capabilities }
  elseif method == vim.lsp.protocol.Methods.shutdown then
    self.stopped = true
    return
  elseif method == vim.lsp.protocol.Methods.EXIT then
    if self.dispatchers.on_exit then
      self.dispatchers.on_exit(0, 0)
    end
  else
    if not self.stopped then
      local request_method = self.request_map[method]
      if request_method then
        return request_method(params)
      end
    end
  end
end

---@param method vim.lsp.protocol.Method|string LSP method name.
---@param params table? LSP request params.
---@param callback fun(err: lsp.ResponseError|nil, result: any)
---@param notify_callback fun(message_id: integer)?
function LanguageServer:request(method, params, callback, notify_callback)
  self.logger:trace("received LSP request for method " .. method)

  local err, res = self:_handle(method, params)
  vim.schedule_wrap(callback)(err, res)

  if notify_callback then
    -- copy before scheduling to make sure it hasn't changed
    local id_to_clear = self.message_id
    vim.schedule(function()
      notify_callback(id_to_clear)
    end)
  end

  return true, self.message_id
end

---@param method string LSP method name.
---@param params table? LSP request params.
function LanguageServer:notify(method, params)
  self.logger:trace("received LSP notification for method " .. method)
  self:_handle(method, params)
end

return LanguageServer
