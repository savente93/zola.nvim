# Zola.nvim

Zola integration for Neovim, written in Lua. Build, serve, check, and scaffold your [Zola](https://www.getzola.org/) static sites without leaving your editor.

---

## ✨ Features

- 🛠️ **Build**, **check** and **serve** your site from inside Neovim
- 📝 **Scaffold** create new sections and pages with default TOML front matter
- 🔧 **Configurable** options per command for streamlined workflows

---

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

## ⚙️Configuration

### Default configuration

The default configuration is as such:

```lua
require('zola').setup({
    config = {
        common = { root = nil }, -- the root of the site to be applied to all function calls
        build = { -- any config to be used when calling `zola build`
            force = false, -- overwrite files already present at output_dir
            minify = true, -- minify output pages
            drafts = false, -- include drafts in the output
        },
        serve = { -- options to be used with `zola serve`
            drafts = false, -- include draft pages and sections in preview
            open = true, -- open the preview in default browser
            fast = false, -- only rebuild pages necessary instead of whole site
        },
        check = { -- options to be used in `zola check`
            drafts = false, -- also check any pages and sections maked as drafrs
            skip_external_links = false, -- don't check whether external links are broken
        },
        page_defaults = { -- any options used when creating new pages (zola.nvim only)
            page_is_dir = true, -- pages are located at page-slug/index.md instead of page-slug.md
            force = false, -- continue and oferwrite files it already exists at provided path
            draft = false, -- mark created page as draft
            open = true, -- open the new page file in a new neovim buffer
        },
        section_defaults = { -- any options used when creating new sections (zola.nvim only)
            force = false, -- continue and overwrite if specified path already exists
            draft = false, -- mark created section as draft
            open = false, -- open the _index.md of new section in a new buffer
        },
    })

```

All these configuration options will be used by the functions, and can be overridden by passing options directly to the function. See example usage for options on the function arguments (function arguments are a super set of the default configuration).

All functions accept a `root` parameter for if you want to perform that action for a site somewhere else, for example because you have a site for documentation located at `docs/site`. If neither the function call nor the config provide it this will default to `vim.fn.getcwd()`.

```lua
local zola = require("zola")

vim.keymap.set("n", "<leader>zbp", function() 
    require("zola").build{ root = "docs/site", output_dir = "docs/build" }
end, {desc = "Serve release version of site"})

vim.keymap.set("n", "<leader>zc", function() 
    require("zola").check()
end, {desc = "Check the site"})

vim.keymap.set("n", "<leader>zsd", function() 
    require("zola").serve{  drafts = true }
end, {desc = "Serve the site with drafts"})

```

You can also create a more flexible experience by intergrating with `vim.ui.input()` like so: 

```lua

vim.keymap.set("n", "<leader>zns", function()
    vim.ui.input({prompt = "Enter section slug: "}, function(result)
        require("zola").create_section({ slug = "blog/" .. result, page_is_dir = true, draft = true, open = true})
    end)
end, {desc = "Build release version of site"})

vim.keymap.set("n", "<leader>znp", function()
    vim.ui.input({prompt = "Enter page slug: "}, function(result)
        require("zola").create_page({ slug = "blog/" .. result, page_is_dir = true, draft = true, open = true}),
    end)
end, {desc = "Create a new blog post"})

vim.keymap.set("n", "<leader>zns", function() 
    vim.ui.input({prompt = "Enter section slug: "}, function(result) 
        require("zola").create_section({ slug = "blog/" .. result, draft = true, open = true})
    end)
end, {desc = "Create a new blog section"})

```

