local M = {}

---@class neomarkdown.HtmlTag
---@field is_block boolean?
---@field prefix string?
---@field suffix string?
---@field start_newline boolean?
---@field end_newline boolean?

---@type table<string, neomarkdown.HtmlTag>
M.tags = {
  h1 = { is_block = true, prefix = "# ", start_newline = true, end_newline = true },
  h2 = { is_block = true, prefix = "## ", start_newline = true, end_newline = true },
  h3 = { is_block = true, prefix = "### ", start_newline = true, end_newline = true },
  h4 = { is_block = true, prefix = "#### ", start_newline = true, end_newline = true },
  h5 = { is_block = true, prefix = "##### ", start_newline = true, end_newline = true },
  h6 = { is_block = true, prefix = "###### ", start_newline = true, end_newline = true },
  p = { is_block = true },
  div = { is_block = true },
  tr = { is_block = true },
  thead = { is_block = true },
  table = { is_block = true },
  tbody = { is_block = true },
  br = { is_block = true, end_newline = true },
  form = { is_block = true },
  ul = { is_block = true },
  ol = { is_block = true },
  li = { is_block = true, prefix = "- " },
  article = { is_block = true, end_newline = true },
  hr = { is_block = true, prefix = "---", end_newline = true },
  -- inline
  td = { prefix = "|" },
  th = { prefix = "|" },
  time = { prefix = " `", suffix = "` " },
  code = { prefix = " `", suffix = "` " },
  strong = { prefix = " `", suffix = "` " },
  small = { prefix = " `", suffix = "` " },
  b = { prefix = " `", suffix = "` " },
  figcaption = { prefix = " `", suffix = "` " },
}

return M
