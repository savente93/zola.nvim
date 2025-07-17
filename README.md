# Zola.nvim

Zola integration for Neovim, written in Lua. Build, serve, check, and scaffold your [Zola](https://www.getzola.org/) static sites without leaving Neovim.

## ✨ Features

- 🛠️ **Build**, **check**, and **serve** your site from inside Neovim
- 📝 **Create** new sections and pages with default TOML front matter
- 🔧 **Configurable** options per command for streamlined workflows

## ⚡️ Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'savente93/zola.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('zola').setup()
  end
}
```

## ⚙️ Configuration

### Default configuration

```lua
require('zola').setup({
  config = {
    common = { root = nil }, -- root of the site, applied to all function calls

    build = { -- options for `zola build`
      force = false, -- overwrite files already present at output_dir
      minify = true, -- minify output pages
      drafts = false, -- include drafts in the output
    },

    serve = { -- options for `zola serve`
      drafts = false, -- include draft pages and sections in preview
      open = true, -- open the preview in the default browser
      fast = false, -- only rebuild necessary pages instead of the whole site
    },

    check = { -- options for `zola check`
      drafts = false, -- also check any pages and sections marked as drafts
      skip_external_links = false, -- don't check whether external links are broken
    },

    page_defaults = { -- options used when creating new pages
      page_is_dir = true, -- pages are located at page-slug/index.md instead of page-slug.md
      force = false, -- overwrite files if they already exist at the provided path
      draft = false, -- mark created page as draft
      open = true, -- open the new page file in a new Neovim buffer
    },

    section_defaults = { -- options used when creating new sections
      force = false, -- overwrite if the specified path already exists
      draft = false, -- mark created section as draft
      open = false, -- open the _index.md of the new section in a new buffer
    },
  }
})
```

All these configuration options are used by the functions and can be overridden by passing options directly to the function. See the example usage section for function-specific options (function arguments are a superset of the default configuration).

All functions accept a `root` parameter if you want to perform that action for a site located elsewhere, for example if you have a documentation site in `docs/site`. If neither the function call nor the config provides it, this defaults to `vim.fn.getcwd()`.

## 🚀 Usage

### 💡 User Commands 
By default, `zola.nvim` does not create any keybindings, but it provides the following commands:

- `ZolaServe`
- `ZolaCheck`
- `ZolaBuild`
- `ZolaCreatePage`
- `ZolaCreateSection`

User commands take arguments in the form `key=bool`. By default, if you pass a known argument it will be toggled on:

```
:ZolaBuild draft minify
```

will call the build functionality with drafts and minifying enabled. You can also disable them explicitly:

```
:ZolaBuild draft=false minify=false
```

Options passed will be apllied in the following precidence from highest to lowest: 
1. function arguments
2. user config options special to that function (e.g. `config.serve`, or `config.page_defaults`)
3. user config optoins common to everything (e.g. `config.common`)

Currently, supplying paths and slugs directly via user commands is not supported. For examples on how to supply them either use the user config, or see the lua section below. To avoid impacting startup time, user commands are kept deliberately minimal. 

## Lua
Using lua you can create keybindings for the different actions you might want to take. For example: 

```lua
local zola = require("zola")

vim.keymap.set("n", "<leader>zbd", function()
 require("zola"). build { root = "docs/site", drafts = true, output_dir = "docs/build" }
end, { desc = "Build version of site including drafts" })

vim.keymap.set("n", "<leader>zbp", function()
 require("zola"). build { root = "docs/site", output_dir = "docs/build" }
end, { desc = "Build release version of site" })

vim.keymap.set("n", "<leader>zc", function()
  require("zola").check()
end, { desc = "Check the site" })

vim.keymap.set("n", "<leader>zsp", function()
  require("zola").serve { drafts = true }
end, { desc = "Serve the release version of the site" })

vim.keymap.set("n", "<leader>zsd", function()
  require("zola").serve { drafts = true }
end, { desc = "Serve the site with drafts" })

```

### 📝 Creating sections and pages

In addition to simply wrapping the binary, `zola.nvim` also provides functionality to create new content in a Zola site.
You can create a more flexible experience by integrating with `vim.ui.input()`. For example, if you always want to create sections and pages in the `content/blog` folder:

```lua
vim.keymap.set("n", "<leader>zns", function()
  vim.ui.input({ prompt = "Enter section slug: " }, function(result)
    require("zola").create_section({
      slug = "blog/" .. result,
      draft = true,
      open = true
    })
  end)
end, { desc = "Create a new blog section" })

vim.keymap.set("n", "<leader>znp", function()
  vim.ui.input({ prompt = "Enter page slug: " }, function(result)
    require("zola").create_page({
      slug = "blog/" .. result,
      page_is_dir = true,
      draft = true,
      open = true
    })
  end)
end, { desc = "Create a new blog post" })
```


### 📁 Slugs and paths

Slugs entered using the `create_page` and `create_section` functions are interpreted as relative to the `content` folder of the Zola site.

- When creating sections, trailing slashes are allowed but not required.
- When creating a page and `page_is_dir` is set to `false`, the `.md` at the end of the slug is allowed but not required.

