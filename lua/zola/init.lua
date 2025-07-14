local Path = require 'plenary.path'
local uv = vim.uv
local ERROR = vim.log.levels.ERROR
local WARN = vim.log.levels.WARN
local INFO = vim.log.levels.INFO

---@class zola_plugin
local M = {}

local function setup_zola_syntax()
    -- shoutout to Yurii Kulchevich (@yorik1984) for this one
  vim.api.nvim_exec2([[
    " Reset current syntax to avoid duplicate regions
    unlet b:current_syntax

    " Include TOML syntax for front matter
    syntax include @TOML syntax/toml.vim
    syntax region tomlFrontMatter matchgroup=frontMatter start="\%^[ \t\n\r]*\_^[ \t]*+++[ \t]*$" end="^[ \t]*+++[ \t]*$" contains=@TOML keepend
    hi link frontMatter Delimiter
    syntax cluster mkdNonListItem add=tomlFrontMatter

    " Reset again before Jinja
    unlet b:current_syntax

    " Include Jinja syntax for templates
    syntax include @Jinja syntax/jinja.vim
    syntax region zolaObject start="{{" end="}}" contains=@Jinja keepend
    syntax region zolaTag start="{%" end="%}" contains=@Jinja keepend

    syntax cluster mkdNonListItem add=zolaObject
    syntax cluster mkdNonListItem add=zolaTag
  ]], {})
end

--- Merge two tables with `t1` taking precedence over `t2`.
---@param t1 table
---@param t2 table
---@return table
local function merge_tables(t1, t2)
    local result = {}

    -- First copy all key-value pairs from t2
    for k, v in pairs(t2) do
        result[k] = v
    end

    -- Then overwrite with key-value pairs from t1
    for k, v in pairs(t1) do
        result[k] = v
    end

    return result
end

--- Strip trailing slashes from a path safely.
---@param path string
---@return string
local function strip_trailing_slash(path)
    if path == '/' then
        return path
    end
    local stripped = path:gsub('/*$', '')
    return stripped
end

--- Run an asynchronous job with error checking.
---@param cmd string[]
---@param opts table
---@return integer job_id
local function run_job(cmd, opts)
    local job_id = vim.fn.jobstart(cmd, opts)
    if job_id <= 0 then
        vim.notify('Failed to start job: ' .. table.concat(cmd, ' '), ERROR)
    end
    return job_id
end

--- Plugin configuration defaults.
M.config = {
    build = { force = false, minify = true, drafts = false },
    serve = {
        force = false,
        drafts = false,
        open = true,
        fast = false,
    },
    check = { drafts = false, skip_external_links = false },
}

--- Setup user configuration, merging with defaults.
---@param user_config table|nil
function M.setup(user_config)
    M.config = vim.tbl_deep_extend('force', M.config, user_config or {})
end

--- Discover Zola config.toml in project root.
---@param root string|nil
---@return Path|nil
function M._discover_config_file(root)
    local project_root = strip_trailing_slash(root or vim.fn.getcwd())
    local config_path = Path:new(project_root):joinpath 'config.toml'
    return config_path:exists() and config_path or nil
end

--- Discover Zola content folder in project root.
---@param root string|nil
---@return Path|nil
function M._discover_content_folder(root)
    local project_root = strip_trailing_slash(root or vim.fn.getcwd())
    local content_path = Path:new(project_root):joinpath 'content'
    return content_path:exists() and content_path or nil
end

--- Determine if a folder is a Zola site.
---@param root string|nil
---@return boolean
function M.is_zola_site(root)
    return M._discover_config_file(root) ~= nil and M._discover_content_folder(root) ~= nil
end

--- Build the Zola site.
---@param opts { root?: string, force?: boolean, draft?: boolean, open?: boolean, output_dir?: string}
function M.build(opts)
    local cmd = { 'zola' }
    local used_opts = merge_tables(opts, M.config.build)

    if used_opts.root then
        vim.list_extend(cmd, { '--root', used_opts.root })
    end

    table.insert(cmd, 'build')

    if used_opts.force then
        table.insert(cmd, '--force')
    end

    if used_opts.minify then
        table.insert(cmd, '--minify')
    end
    if used_opts.drafts then
        table.insert(cmd, '--drafts')
    end
    if used_opts.output_dir then
        vim.list_extend(cmd, { '--output_dir', used_opts.output_dir })
    end

    run_job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,

        on_stderr = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify('[Zola]: ' .. line, ERROR)
                end
            end
        end,
        on_exit = function(_, code)
            if code == 0 then
                vim.notify('[Zola] Site built successfully!', INFO)
            else
                vim.notify('[Zola] Build failed with code ' .. code, ERROR)
            end
        end,
    })
end

--- Check the Zola site for errors and warnings.
---@param opts {root?: string, drafts?: boolean, skip_external_links?: boolean}
function M.check(opts)
    local cmd = { 'zola' }
    local check = M.config.check

    local used_opts = merge_tables(opts, M.config.check)

    if used_opts.root then
        vim.list_extend(cmd, { '--root', used_opts.root })
    end

    table.insert(cmd, 'check')
    if check.skip_external_links then
        table.insert(cmd, '--skip-external-links')
    end
    if check.drafts then
        table.insert(cmd, '--drafts')
    end

    run_job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,

        on_stderr = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify(line, ERROR)
                end
            end
        end,

        on_exit = function(_, code)
            if code == 0 then
                vim.notify('[Zola] Check successful', INFO)
            else
                vim.notify('[Zola] Check failed ', ERROR)
            end
        end,
    })
end

--- Serve the Zola site locally with live reload.
---@param opts {root?: string, output_dir?: string, force?: boolean, drafts?: boolean, open?: boolean,  fast?: boolean }
function M.serve(opts)
    local cmd = { 'zola' }
    local used_opts = merge_tables(opts, M.config.serve)

    if used_opts.root then
        vim.list_extend(cmd, { '--root', used_opts.root })
    end

    table.insert(cmd, 'serve')

    if used_opts.force then
        table.insert(cmd, '--force')
    end

    if used_opts.open then
        table.insert(cmd, '--open')
    end
    if used_opts.fast then
        table.insert(cmd, '--fast')
    end
    if used_opts.incl_drafts then
        table.insert(cmd, '--drafts')
    end
    if used_opts.output_dir then
        vim.list_extend(cmd, { '--output_dir', used_opts.output_dir })
    end

    local serve_buf_nr = vim.api.nvim_create_buf(false, true)
    vim.bo[serve_buf_nr].bufhidden = 'wipe'
    vim.bo[serve_buf_nr].buftype = 'nofile'
    vim.bo[serve_buf_nr].filetype = 'zola-log'

    vim.cmd 'vsplit'
    vim.api.nvim_win_set_buf(0, serve_buf_nr)

    -- Start terminal job directly
    run_job(cmd, {
        stdout_buffered = false,
        stderr_buffered = false,
        term = true,
    })
end

--- Render default TOML front matter for new content.
---@param draft boolean|nil
---@return string
local function render_front_matter(draft)
    local date = os.date '%Y-%m-%d'
    return table.concat({
        '+++',
        'title = ""',
        'date = ' .. date,
        draft and 'draft = true' or nil,
        '+++',
        '',
    }, '\n')
end

--- Write content to file at given path.
---@param path string
---@param content string
local function write_to_file(path, content)
    local fd, err = uv.fs_open(path, 'w', 420) -- permission 0644
    if not fd then
        return vim.notify('Failed to open file: ' .. err, ERROR)
    end

    local ok, write_err = uv.fs_write(fd, content, -1)
    uv.fs_close(fd)
    if not ok then
        vim.notify('Failed to write file: ' .. write_err, ERROR)
    end
end

--- Put cursor inside empty title quotes in front matter.
local function put_cursor_at_title()
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    for i, line in ipairs(lines) do
        local target_col = line:find 'title%s*=%s*""'
        if target_col then
            local quote_col = line:find '""'
            if quote_col then
                vim.api.nvim_win_set_cursor(0, { i, quote_col })
                vim.api.nvim_feedkeys('i', 'n', false)
            end
            break
        end
    end
end

--- Create a new section with _index.md in the content folder.
---@param opts { slug: string, root?: string, force?: boolean, draft?: boolean, open?: boolean }
function M.create_section(opts)
    vim.validate { path = { opts.slug, 'string' } }

    local used_opts = merge_tables(opts, M.config.section_defaults)

    local content_folder = M._discover_content_folder(used_opts.root)
    if not content_folder then
        return vim.notify('Could not determine content folder.', ERROR)
    end

    local section_path = Path:new(content_folder):joinpath(used_opts.slug)
    if section_path:exists() and not used_opts.force then
        return vim.notify('Section already exists!', ERROR)
    end

    if used_opts.force and section_path:exists() then
        uv.fs_rmdir(section_path:absolute())
    end
    uv.fs_mkdir(section_path:absolute(), 493) -- permission 0755

    local final_path = section_path:joinpath '_index.md'
    write_to_file(final_path:absolute(), render_front_matter(used_opts.draft))

    if used_opts.open then
        vim.cmd('e ' .. final_path:absolute())
        put_cursor_at_title()
    end
end

--- Create a new page in the content folder.
---@param opts { slug: string, root?: string, force?: boolean, draft?: boolean, open?: boolean, page_is_dir?: boolean }
function M.create_page(opts)
    vim.validate { slug = { opts.slug, 'string' } }

    local used_opts = merge_tables(opts, M.config.page_defaults)

    local content_folder = M._discover_content_folder(used_opts.root)
    if not content_folder then
        return vim.notify('Could not determine content folder.', ERROR)
    end

    local page_path = Path:new(content_folder):joinpath(used_opts.slug)
    local final_path = page_path

    if used_opts.page_is_dir false then
        if page_path:exists() and not used_opts.force then
            return vim.notify('Page directory already exists!', ERROR)
        elseif page_path:exists() then
            uv.fs_unlink(page_path:absolute())
        end

        uv.fs_mkdir(page_path:absolute(), 493)
        final_path = page_path:joinpath 'index.md'
    else
        -- Note: Path.filename returns the full path string in plenary
        if not page_path.filename:match '.md$' then
            final_path = Path:new(page_path.filename .. '.md')
        end
    end

    write_to_file(final_path:absolute(), render_front_matter(used_opts.draft))

    if used_opts.open then
        vim.cmd('e ' .. final_path:absolute())
        put_cursor_at_title()
    end
end

return M
