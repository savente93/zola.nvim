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
    build = {
        root = nil, -- root of the site, by default `vim.fn.getcwd()`
        force = false, -- build even if output dir exists
        minify = true, -- minify output html
        drafts = false, -- render drafts
        output_dir = nil,  -- dir to place the rendered site, by default `public`
    },
    serve = {
        root = nil, -- root of the site, by default `vim.fn.getcwd()`
        force = false,-- build even if output dir exists
        drafts = false,-- render drafts in preview
        open = false, -- open preview in browser
        fast = false, -- only rebuild changed pages
    },
    check = {
        root = nil, -- root of the site, by default `vim.fn.getcwd()`
        drafts = false, -- also check drafts
        skip_external_links = false, -- do not check external links
    },
    page_defaults = {
        page_is_dir = true -- pages are located at `page-slug/index.md` instead of `page-slug.md`
        root = nil, 
        force = false, -- overwrite a file if it already exists
        draft = false, -- mark new page as draft
        open = true, -- open the file after it has been created
    }, 
    section_defaults = {
        root = nil,
        force = false,
        draft = false,
        open = false
    }
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

### Configuring keybinding only in zola projects

`Zola.nvim` is not a very heavy plugin, so lazy loading isn't implemented at this time. However, you can only configure keybindings for the user commands when opening neovim in the root of a zola site like this: 

```lua
{
    'savente93/zola.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        if zola.is_zola_site() then
            -- put your keybind mappings here
        end
    end
}

```

## 🚧 Roadmap

Zola.nvim is a work in progress and it's use will be developed over time. It is currently in an early and thus quite maleable state. As such for now it will mostly be focused on my needs.
However I'm open to implementing features based on requests. Some ideas I
would consider implementing upon request:

1. A Telescope picker/browser for themes
2. Completion for taxonomies and taxonomy items
3. Completion for internal linking
