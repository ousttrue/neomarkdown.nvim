---@class neomarkdown.Params
---@field debug boolean?
---@field debug_content boolean?
---@field curl_command string[]

local M = {}

---@param opts neomarkdown.Params?
function M.setup(opts)
  opts = opts or {}

  --
  -- BufReadCmd
  --
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

  --
  -- LanguageServer
  --
  local LanguageServer = require "neomarkdown.LanguageServer"
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown" },
    callback = function()
      LanguageServer.launch()
    end,
  })
  vim.api.nvim_create_user_command("MdlsLaunch", function()
    LanguageServer.launch()
  end, {})

  local Logger = require "neomarkdown.Logger"
  vim.api.nvim_create_user_command("LlsLog", function()
    vim.cmd(string.format("edit %s", Logger.get_log_path()))
  end, {})

  --
  -- edit command
  --
  local utils = require "neomarkdown.utils"
  vim.keymap.set("n", "<C-y>a", utils.markdown_title, {})
end

return M
