---@class neomarkdown.Params
---@field debug boolean?
---@field debug_content boolean?
---@field curl_command string[]

local M = {}

---@param opts neomarkdown.Params?
function M.setup(opts)
  opts = opts or {}
  opts.curl_command = opts.curl_command
      or {
        "curl",
        "-0",
        "-L",
        "-i",
        "-H",
        "USER-AGENT: w3m/0.5.3+git20230121",
      }

  local bufread = require "neomarkdown.bufread"
  vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = { "http://*", "https://*" },
    ---@param ev vim.api.keyset.create_autocmd.callback_args
    callback = function(ev)
      bufread.on_bufreadcmd(ev.buf, ev.file, opts)
    end,
  })
end

return M
