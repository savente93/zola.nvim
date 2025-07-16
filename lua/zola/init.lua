---@class zola_plugin
local M = {}

--- Plugin configuration defaults.
M.config = {
    common = { root = nil },
    build = { force = false, minify = true, drafts = false },
    serve = {
        force = false,
        drafts = false,
        open = true,
        fast = false,
    },
    check = { drafts = false, skip_external_links = false },
    page_defaults = {
        page_is_dir = true,
        force = false,
        draft = false,
        open = true,
    },
    section_defaults = {
        force = false,
        draft = false,
        open = false,
    },
}

--- Setup user configuration, merging with defaults.
---@param user_config table|nil
function M.setup(user_config)
    M.config = vim.tbl_deep_extend('force', M.config, user_config or {})
end

--- Determine if a folder is a Zola site.
---@param root string|nil
---@return boolean
function M.is_zola_site(root)
    local site_utils = require 'zola.site'
    return site_utils._discover_config_file(root) ~= nil and site_utils._discover_content_folder(root) ~= nil
end

--- Build the Zola site.
---@param opts { root?: string, force?: boolean, draft?: boolean, open?: boolean, output_dir?: string}
function M.build(opts)
    local cmd = require('zola.cmd')._compute_build_args(opts, M.config.build, M.config.common)

    require('zola.utils').run_job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,

        on_stderr = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify('[Zola]: ' .. line, vim.log.levels.ERROR)
                end
            end
        end,
        on_exit = function(_, code)
            if code == 0 then
                vim.notify('[Zola] Site built successfully!', vim.log.levels.INFO)
            else
                vim.notify('[Zola] Build failed with code ' .. code, vim.log.levels.ERROR)
            end
        end,
    })
end

--- Check the Zola site for errors and warnings.
---@param opts {root?: string, drafts?: boolean, skip_external_links?: boolean}
function M.check(opts)
    local cmd = require('zola.cmd')._compute_check_args(opts, M.config.check, M.config.common)
    require('zola.utils').run_job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,

        on_stderr = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify(line, vim.log.levels.ERROR)
                end
            end
        end,

        on_exit = function(_, code)
            if code == 0 then
                vim.notify('[Zola] Check successful', vim.log.levels.INFO)
            else
                vim.notify('[Zola] Check failed ', vim.log.levels.ERROR)
            end
        end,
    })
end

--- Serve the Zola site locally with live reload.
---@param opts {root?: string, output_dir?: string, force?: boolean, drafts?: boolean, open?: boolean,  fast?: boolean }
function M.serve(opts)
    local cmd = require('zola.cmd')._compute_serve_args(opts, M.config.common, M.config.serve)
    local serve_buf_nr = vim.api.nvim_create_buf(false, true)
    vim.bo[serve_buf_nr].bufhidden = 'wipe'
    vim.bo[serve_buf_nr].buftype = 'nofile'
    vim.bo[serve_buf_nr].filetype = 'zola-log'

    vim.cmd 'vsplit'
    vim.api.nvim_win_set_buf(0, serve_buf_nr)

    -- Start terminal job directly
    require('zola.utils').run_job(cmd, {
        stdout_buffered = false,
        stderr_buffered = false,
        term = true,
    })
end

--- Create a new section with _index.md in the content folder.
---@param opts { slug: string, root?: string, force?: boolean, draft?: boolean, open?: boolean }
function M.create_section(opts)
    vim.validate { path = { opts.slug, 'string' } }
    local Path = require 'plenary.path'

    local used_opts = require('zola.utils').merge_tables(opts, M.config.section_defaults)

    local content_folder = require('zola.site')._discover_content_folder(used_opts.root)
    if not content_folder then
        return vim.notify('Could not determine content folder.', vim.log.levels.ERROR)
    end

    local section_path = Path:new(content_folder):joinpath(used_opts.slug)
    if section_path:exists() and not used_opts.force then
        return vim.notify('Section already exists!', vim.log.levels.ERROR)
    end

    if used_opts.force and section_path:exists() then
        vim.uv.fs_rmdir(section_path:absolute())
    end
    vim.uv.fs_mkdir(section_path:absolute(), 493) -- permission 0755

    local final_path = section_path:joinpath '_index.md'
    require('zola.utils').write_to_file(final_path:absolute(), require('zola.content').render_front_matter(used_opts.draft))

    if used_opts.open then
        vim.cmd('e ' .. final_path:absolute())
        require('zola.content').put_cursor_at_title()
    end
end

--- Create a new page in the content folder.
---@param opts { slug: string, root?: string, force?: boolean, draft?: boolean, open?: boolean, page_is_dir?: boolean }
function M.create_page(opts)
    vim.validate { slug = { opts.slug, 'string' } }
    local Path = require 'plenary.path'

    local used_opts = require('zola.utils')._merge_tables(opts, M.config.page_defaults)

    local content_folder = require('zola.site')._discover_content_folder(used_opts.root)
    if not content_folder then
        return vim.notify('Could not determine content folder.', vim.log.levels.ERROR)
    end

    local page_path = Path:new(content_folder):joinpath(used_opts.slug)
    local final_path = page_path

    if used_opts.page_is_dir then
        if page_path:exists() and not used_opts.force then
            return vim.notify('Page directory already exists!', vim.log.levels.ERROR)
        elseif page_path:exists() then
            vim.uv.fs_unlink(page_path:absolute())
        end

        vim.uv.fs_mkdir(page_path:absolute(), 493)
        final_path = page_path:joinpath 'index.md'
    else
        -- Note: Path.filename returns the full path string in plenary
        if not page_path.filename:match '.md$' then
            final_path = Path:new(page_path.filename .. '.md')
        end
    end

    require('zola.utils').write_to_file(final_path:absolute(), require('zola.content').render_front_matter(used_opts.draft))

    if used_opts.open then
        vim.cmd('e ' .. final_path:absolute())
        require('zola.content').put_cursor_at_title()
    end
end
return M
