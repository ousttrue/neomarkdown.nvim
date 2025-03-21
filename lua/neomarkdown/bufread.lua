local HttpResponse = require "neomarkdown.HttpResponse"

local M = {}

---@param buf integer
---@param url string
---@param opts neomarkdown.Params
function M.on_bufreadcmd(buf, url, opts)
  local content
  local fold_end = 1

  ---@type string[]
  local lines = {}

  if opts.debug_content then
    content = [[
  <html>
    <body>
      <p>hello</p>
    </body>
  </html>
  ]]
  else
    local res = HttpResponse.get(url, opts)

    res:render_to_lines(lines)
    fold_end = #lines

    content = res.content
    assert(content)
    if res.map["Content-Type"] == "text/html; charset=Shift_JIS" then
      content = vim.iconv(content, "shift_jis", "utf-8", {})
    end
  end

  local renderer = require "neomarkdown.renderer"
  renderer.render_to_lines(lines, content)

  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })

  vim.api.nvim_buf_set_lines(buf, -2, -1, true, lines)
  -- vim.api.nvim_buf_set_lines(buf, -2, -1, true, vim.split(body, "\n"))
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  vim.keymap.set("n", "j", "gj", { buffer = buf, noremap = true })
  vim.keymap.set("n", "k", "gk", { buffer = buf, noremap = true })

  vim.api.nvim_set_current_buf(buf)
  -- vim.cmd "norm! zM"
  -- local ufo = require "ufo"
  -- ufo.applyFolds(0, { 1, -1 })
  -- ufo.closeFoldsWith(1)
  vim.cmd "norm! gg"
  vim.cmd("norm! " .. fold_end .. "j")
  vim.cmd "norm! zt"
end

return M
