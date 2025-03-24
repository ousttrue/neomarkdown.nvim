local html = require "neomarkdown.html"

---@class PushLine
---@field lines string[]
---@field src string
---@field texts string[]
local PushLine = {}
PushLine.__index = PushLine

---@param lines string[]
---@param src string
---@return PushLine
function PushLine.new(lines, src)
  local self = setmetatable({
    lines = lines,
    src = src,
    texts = {},
    elements = {},
  }, PushLine)
  return self
end

function PushLine:push_text(text)
  assert(type(text) == "string")
  text = text:gsub("%s", " ")
  text = text:match "^%s*(.-)%s*$"
  if #text == 0 then
    return
  end
  table.insert(self.texts, text)
end

function PushLine:push_line(text)
  assert(type(text) == "string")
  self:flush_texts()
  table.insert(self.lines, text)
end

---@return boolean
function PushLine:flush_texts()
  if self.texts[#self.texts] == "- " then
    table.remove(self.texts)
  end
  local text = table.concat(self.texts, "")
  self.texts = {}

  if text:match "^%s*$" then
    return false
  end

  table.insert(self.lines, text)
  return true
end

function PushLine:newline()
  if #self.lines > 0 and not self.lines[#self.lines]:match "^%s*$" then
    table.insert(self.lines, "")
  end
end

function PushLine:start_tag(text, closing)
  assert(type(text) == "string")
  local tag_name = text:match "^<(%w+)"
  assert(tag_name)
  tag_name = tag_name:lower()

  local tag = html.tags[tag_name]
  if tag then
    if tag.is_block then
      self:flush_texts()
      if tag.start_newline then
        self:newline()
      end
      if tag.prefix and #tag.prefix > 0 then
        table.insert(self.texts, tag.prefix)
      end
    else
      if tag.prefix then
        table.insert(self.texts, tag.prefix)
      end
    end
  else
    -- if closing then
    --   table.insert(self.texts, "<" .. tag_name .. "/>")
    -- else
    --   table.insert(self.texts, "<" .. tag_name .. ">")
    -- end
  end
end

function PushLine:end_tag(text)
  assert(type(text) == "string")
  local tag_name = text:match "^<(%w+)"
  assert(tag_name)
  tag_name = tag_name:lower()

  local tag = html.tags[tag_name]
  if tag then
    if tag.is_block then
      self:flush_texts()
      if tag.end_newline then
        self:newline()
      end
    else
      if tag.suffix then
        table.insert(self.texts, tag.suffix)
      end
    end
  else
    -- table.insert(self.texts, "</" .. tag_name .. ">")
  end
end

return PushLine
