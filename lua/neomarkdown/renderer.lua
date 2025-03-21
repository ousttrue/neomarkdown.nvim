local entity = require "neomarkdown.entity"
local PushLine = require "neomarkdown.PushLine"

local M = {}

---@param node TSNode
---@param callback fun(node: TSNode):boolean
local function traverse(node, callback)
  if callback(node) then
    for i = 0, node:named_child_count() - 1 do
      local child = node:named_child(i)
      if child then
        traverse(child, callback)
      end
    end
  end
end

---@param node TSNode
---@param type_name string
---@return TSNode?
local function find_child_by_type(node, type_name)
  for i = 0, node:named_child_count() - 1 do
    local child = node:named_child(i)
    if child then
      if child:type() == type_name then
        return child
      end
    end
  end
end

---@param src string
---@param node TSNode
---@return string?
local function html_get_tag_from_element(src, node)
  if node:type() ~= "element" then
    return
  end

  local child = find_child_by_type(node, "start_tag")
  if not child then
    return
  end

  return vim.treesitter.get_node_text(child, src)
end

---@param src string
---@param node TSNode
---@return string
local function get_text(src, node)
  local node_type = node:type()
  local out = ""
  if node_type == "text" or node_type == "entity" then
    local text = vim.treesitter.get_node_text(node, src)
    if #text > 0 then
      text = entity.decode(text)
      out = out .. text
    end
  else
    -- print(node_type)
  end

  for i = 0, node:child_count() - 1 do
    local child = node:child(i)
    if child then
      out = out .. get_text(src, child)
    end
  end

  return out
end

---@param src string
---@param node TSNode
---@return string?
local function make_link(src, node)
  assert(node:type() == "element")
  local url
  local text = ""
  for i = 0, node:named_child_count() - 1 do
    local child = node:named_child(i)
    if child then
      local child_type = child:type()
      if child_type == "start_tag" then
        local a_text = vim.treesitter.get_node_text(child, src)
        url = a_text:match "%shref%s*=%s*(%S+)"
        if not url then
          url = a_text:match "%sHREF%s*=%s*(%S+)"
        end
        if url then
          url = url:gsub("&amp;", "&")
          local m = url:match '^"([^"]*)">?$'
          if m then
            url = m
          end
        else
          -- print("no href", a_text)
        end
      else
        text = text .. get_text(src, child)
      end
    end
  end

  if url then
    local g_redirect = url:match "^/url%?q=([^&]*)"
    if g_redirect then
      url = g_redirect
    end

    local title = entity.decode(text:gsub("\n", " "))
    if title:match "^%s*$" then
      -- title = "no_text"
    else
      return ("[%s](%s)"):format(title, vim.uri_decode(url))
    end
  end
end

---@param src string
---@return string
local function remove_html_tag(src)
  local dst = ""
  local pos = 1
  while pos <= #src do
    local s, e = src:find("<[^>]+>", pos)
    if not s then
      dst = dst .. src:sub(pos)
      break
    end
    dst = dst .. src:sub(pos, s - 1)
    pos = e + 1
  end
  dst = entity.decode(dst)
  dst = dst:match "(.-)%s*$"

  return dst
end

---@param src string?
---@return string?
local function get_pre_lang(src)
  if not src then
    print "no src"
    return
  end

  local m = src:match '%sdata%-lang="(%w+)"' or ""
  if m and #m > 0 then
    return m
  end

  m = src:match '%sdata%-language="(%w+)"' or ""
  if m and #m > 0 then
    return m
  end

  m = src:match '%sclass="language%-([^"]+)"' or ""
  if m and #m > 0 then
    return m
  end

  -- print('no lang', src)
  return ""
end

---@param lines string[]
---@param content string?
function M.render_to_lines(lines, content)
  assert(content)
  local parser = vim.treesitter.get_string_parser(content, "html")
  local tree = parser:parse()
  if tree then
    local push_line = PushLine.new(lines, content)

    local root = tree[1]:root()
    traverse(root, function(node)
      local node_type = node:type()
      local text = vim.treesitter.get_node_text(node, content)
      if node_type == "document" then
        return true
      end

      local start_tag_text = html_get_tag_from_element(content, node)
      local tag
      if start_tag_text then
        tag = start_tag_text:match "^<(%w+)"
        assert(tag)
        tag = tag:lower()
      end
      --   if tag then
      --     if start_tag_text:match "^<a%s" then
      --     end
      --   end
      -- end

      if tag == "a" then
        local link = make_link(content, node)
        if link then
          push_line:push_text(link)
        end
      elseif tag == "pre" then
        local pre = vim.treesitter.get_node_text(node, content, {})
        pre = remove_html_tag(pre)
        local lang = get_pre_lang(start_tag_text)
        push_line:flush_texts()
        push_line:newline()
        push_line:push_line("```" .. lang)
        local pre_lines = vim.split(pre, "\n")
        for _, l in ipairs(pre_lines) do
          push_line:push_line(l)
        end
        push_line:push_line "```"
        push_line:newline()
      elseif tag == "head" then
      elseif tag == "form" then
      elseif tag == "svg" then
      elseif tag == "dialog" then
      elseif tag == "script_element" then
      elseif tag == "style_element" then
      elseif tag == "doctype" then
      elseif tag == "comment" then
      elseif tag == "iframe" then
      elseif node_type == "element" then
        return true
      elseif node_type == "text" or node_type == "entity" then
        push_line:push_text(entity.decode(text))
      elseif node_type == "start_tag" then
        push_line:start_tag(text)
      elseif node_type == "self_closing_tag" then
        push_line:start_tag(text, true)
      elseif node_type == "end_tag" then
        local parent = node:parent()
        assert(parent)
        local end_tag = html_get_tag_from_element(content, parent)
        assert(end_tag)
        push_line:end_tag(end_tag)
      else
        print(node_type)
      end

      return false
    end)

    push_line:flush_texts()
  end
end

return M
