local M = {}

local CharMap = {
  ["&amp;"] = "&",
  ["&#8211;"] = "–",
}

---@param node TSNode
---@param prefix string
---@param url string
---@param suffix string
local function make_markdown_link(node, prefix, url, suffix)
  -- print(node, url)
  local h = io.popen("curl -s -L " .. url)
  if not h then
    return
  end
  local rawdata = h:read "all"
  h:close()
  if not rawdata then
    return
  end

  -- local t = vim.json.decode(rawdata)
  local begin_s, begin_e = rawdata:find "<title>"
  if begin_s then
    local end_s, end_e = rawdata:find("</title>", begin_e + 1)
    if end_s then
      local title = rawdata:sub(begin_e + 1, end_s - 1)
      if title then
        -- print(url, title)
        -- TODO &quot; => "
        title = string.gsub(title, "&#?%w+;", function(m)
          local ref = CharMap[m]
          if ref then
            return ref
          else
            return m
          end
        end)

        -- https://phelipetls.github.io/posts/template-string-converter-with-neovim-treesitter/#replace-the-string-surroundings-with-
        local start_row, start_col, end_row, end_col = node:range()
        local entity = require "neomarkdown.entity"
        title = entity.decode(title)
        local markdown_link = ("[%s](%s)"):format(title, url)
        vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { prefix .. markdown_link .. suffix })
      end
    end
  end
end

local HTTP_PATTERN = [[^(.*)(https?://[%w%(%)@:%_%+-%.~#?&/=]+)(.*)]]

---@param node TSNode?
---@return TSNode? link_destination
---@return TSNode? inline_link
function M.get_link_destination(node)
  if not node then
    return
  end

  local node_type = node:type()
  if node_type == "link_destination" then
    return node, node:parent()
  end

  if node_type == "link_text" then
    local parent = node:parent()
    if parent then
      for i = 0, parent:named_child_count() - 1 do
        local child = parent:named_child(i)
        if child then
          if child:type() == "link_destination" then
            return child, parent
          end
        end
      end
    end
  end

  if node_type == "inline_link" then
    local parent = node
    for i = 0, parent:named_child_count() - 1 do
      local child = parent:named_child(i)
      if child then
        if child:type() == "link_destination" then
          return child, parent
        end
      end
    end
  end

  print("get_link_destination: link_destination not found", node:type())
end

function M.markdown_title()
  -- https://github.com/nvim-treesitter/nvim-treesitter/blob/master/lua/nvim-treesitter/ts_utils.lua
  local ts_utils = require "nvim-treesitter.ts_utils"
  local node = ts_utils.get_node_at_cursor(0, false)
  if not node then
    return
  end

  local node_type = node:type()
  print(node_type)
  if node_type == "inline" then
    local text = vim.treesitter.get_node_text(node, 0)
    -- replace
    if #text > 0 then
      local prefix, m, suffix = text:match(HTTP_PATTERN)
      if m then
        make_markdown_link(node, prefix, m, suffix)
      end
    end
    return
  end

  -- inlin_link
  -- + [link_text](link_destination)

  local link_destination, inline_link = M.get_link_destination(node)
  if link_destination then
    local text = vim.treesitter.get_node_text(link_destination, 0)
    -- replace
    if #text > 0 then
      local prefix, m, suffix = text:match(HTTP_PATTERN)
      if m then
        make_markdown_link(inline_link, "", m, "")
      end
    end
    return
  end

  --   elseif list[2]:type() == "inline_link" then
  --     -- update
  --     local url = list[2]:named_child(1)
  --     local lines = ts_utils.get_node_text(url)
  --     -- print(url, lines[1])
  --     local prefix, m = lines[1]:match(http_pattern)
  --     if m then
  --       make_markdown_link(list[2], prefix, m)
  --     else
  --       print("not match", lines1[2])
  --     end
  --   end
  -- end
end

return M
