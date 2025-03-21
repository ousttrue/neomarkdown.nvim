---@class neomrkdown.HttpResponse
---@field responses {status:string, header:string}[]
---@field map table<string, string>
---@field content string?
local HttpResponse = {}
HttpResponse.__index = HttpResponse

---@param out string
---@return neomrkdown.HttpResponse
function HttpResponse.new(out)
  assert(out and #out > 0)

  local self = setmetatable({
    responses = {},
    map = {},
  }, HttpResponse)

  while #out > 0 do
    local status, header, body = out:match "^(HTTP.-)\r\n(.-)\r\n\r\n(.*)$"
    if status then
      table.insert(self.responses, { status = status, header = header })
      out = body
    else
      break
    end
  end
  self.content = out

  -- map last response
  local last_response = self.responses[#self.responses]
  for k, v in last_response.header:gmatch "([^:]+):%s*(.-)\r\n" do
    self.map[k] = v
  end

  return self
end

---@param url string
---@param opts neomarkdown.Params
---@return neomrkdown.HttpResponse
function HttpResponse.get(url, opts)
  assert(url:match "^https?://.*")

  -- get http
  local cmd = { unpack(opts.curl_command) }
  table.insert(cmd, url)
  local dl_job = vim.system(cmd, { text = false }):wait()
  local out = dl_job.stdout
  assert(out)
  if opts.debug then
    local fd = vim.uv.fs_open("tmp.html", "w", tonumber("666", 8))
    if fd then
      vim.uv.fs_write(fd, out)
      vim.uv.fs_close(fd)
    end
  end

  -- parse http response
  local res = HttpResponse.new(out)
  return res
end

---@param lines string[]
function HttpResponse:render_to_lines(lines)
  table.insert(lines, "---")
  table.insert(lines, "# vim: ft=markdown")
  table.insert(lines, "responses: [")

  for i, res in ipairs(self.responses) do
    table.insert(lines, "  {")
    table.insert(lines, '    "status": "' .. res.status .. '"')
    if i == #self.responses then
      table.insert(lines, '    "http-header": {')
      for k, v in pairs(self.map) do
        table.insert(lines, '      "' .. k .. '": "' .. v .. '"')
      end
      table.insert(lines, "    },")
    end
    table.insert(lines, "  },")
  end
  table.insert(lines, "]")
  table.insert(lines, "---")
end

return HttpResponse
