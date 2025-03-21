# neomarkdown.nvim

nvim で markdown する諸々。

## features

### BufReadCmd

`http://\*`

- get content by curl
- parse html by tree-sitter
- render TSNode to markdown

### LanguageServer

[none-ls](https://github.com/nvimtools/none-ls.nvim) like lua callback implemantation.

### goto

- url: as is
- local md + absolute path: relative document root. for example docusaurus `docs` relative.
- local md + relative path: base dir + relative path.
- remote md + absolute path: host + absolute path.
- remote md + relative path: base url + relative path.

## install

lazy

```lua
{
  "ousttrue/neomarkdown.nvim",
  opts = {},
},
```
