local Path = require 'plenary.path'
local uv = vim.uv
local ERROR = vim.log.levels.ERROR
local WARN = vim.log.levels.WARN
local INFO = vim.log.levels.INFO

---@class zola_plugin
local M = {}

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
    build = { force = false, minify = true, incl_drafts = false },
    serve = { force = false, incl_drafts = false, open = false, fast = false, no_port_append = false },
    check = { incl_drafts = false, skip_external_links = false },
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
---@param root string|nil
---@param output_dir string|nil
function M.build(root, output_dir)
    local cmd = { 'zola' }
    local build_config = M.config.build

    if root then
        vim.list_extend(cmd, { '--root', root })
    end
    table.insert(cmd, 'build')
    if build_config.force then
        table.insert(cmd, '--force')
    end
    if build_config.minify then
        table.insert(cmd, '--minify')
    end
    if build_config.incl_drafts then
        table.insert(cmd, '--drafts')
    end
    if output_dir then
        vim.list_extend(cmd, { '--output_dir', output_dir })
    end

    run_job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify('[Zola stdout]: ' .. line, WARN)
                end
            end
        end,
        on_stderr = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify('[Zola stderr]: ' .. line, WARN)
                end
            end
        end,
        on_exit = function(_, code)
            if code == 0 then
                vim.notify('[zola_plugin] Site built successfully!', INFO)
            else
                vim.notify('[zola_plugin] Build failed with code ' .. code, ERROR)
            end
        end,
    })
end

--- Check the Zola site for errors and warnings.
---@param root string|nil
function M.check(root)
    local cmd = { 'zola' }
    local check = M.config.check

    if root then
        vim.list_extend(cmd, { '--root', root })
    end

    table.insert(cmd, 'check')
    if check.skip_external_links then
        table.insert(cmd, '--skip-external-links')
    end
    if check.incl_drafts then
        table.insert(cmd, '--drafts')
    end

    run_job(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify('[Zola stdout]: ' .. line, WARN)
                end
            end
        end,
        on_stderr = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify('[Zola stderr]: ' .. line, WARN)
                end
            end
        end,
        on_exit = function(_, code)
            if code == 0 then
                vim.notify('[zola_plugin] Check successful', INFO)
            else
                vim.notify('[zola_plugin] Check failed with code ' .. code, ERROR)
            end
        end,
    })
end

--- Serve the Zola site locally with live reload.
---@param root string|nil
---@param output_dir string|nil
---@param port integer|nil
---@param extra_watch_path string|nil
function M.serve(root, output_dir, port, extra_watch_path)
    local cmd = { 'zola' }
    local serve_config = M.config.serve

    if root then
        vim.list_extend(cmd, { '--root', root })
    end

    table.insert(cmd, 'serve')

    if serve_config.force then
        table.insert(cmd, '--force')
    end
    if serve_config.no_port_append then
        table.insert(cmd, '--no-port-append')
    end
    if port and not serve_config.no_port_append then
        vim.list_extend(cmd, { '--port', port })
    elseif port then
        vim.notify('Port was specified, but so was --no-port-append. Ignoring port', WARN)
    end
    if serve_config.open then
        table.insert(cmd, '--open')
    end
    if serve_config.fast then
        table.insert(cmd, '--fast')
    end
    if serve_config.incl_drafts then
        table.insert(cmd, '--drafts')
    end
    if output_dir then
        vim.list_extend(cmd, { '--output_dir', output_dir })
    end
    if extra_watch_path then
        vim.list_extend(cmd, { '--extra-watch-path', extra_watch_path })
    end

    vim.cmd 'vsplit'
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)

    -- Start terminal job directly
    run_job(cmd, {
        stdout_buffered = false,
        stderr_buffered = false,
        on_exit = function(_, code)
            if code == 0 then
                vim.notify('[zola_plugin] Serve exited successfully!', INFO)
            else
                vim.notify('[zola_plugin] Serve exited with code ' .. code, ERROR)
            end
        end,
        term = true,
    })

    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = 'zola-log'

    vim.notify('Started zola serve', INFO)
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
---@param opts { path: string, root?: string, force?: boolean, draft?: boolean, open?: boolean }
function M.create_section(opts)
    vim.validate { path = { opts.path, 'string' } }

    local content_folder = M._discover_content_folder(opts.root)
    if not content_folder then
        return vim.notify('Could not determine content folder.', ERROR)
    end

    local section_path = Path:new(content_folder):joinpath(opts.path)
    if section_path:exists() and not opts.force then
        return vim.notify('Section already exists!', ERROR)
    end

    if opts.force and section_path:exists() then
        uv.fs_rmdir(section_path:absolute())
    end
    uv.fs_mkdir(section_path:absolute(), 493) -- permission 0755

    local final_path = section_path:joinpath '_index.md'
    write_to_file(final_path:absolute(), render_front_matter(opts.draft ~= false))

    if opts.open ~= false then
        vim.cmd('e ' .. final_path:absolute())
        put_cursor_at_title()
    end
end

--- Create a new page in the content folder.
---@param opts { path: string, root?: string, force?: boolean, draft?: boolean, open?: boolean, page_is_dir?: boolean }
function M.create_page(opts)
    vim.validate { path = { opts.path, 'string' } }

    local content_folder = M._discover_content_folder(opts.root)
    if not content_folder then
        return vim.notify('Could not determine content folder.', ERROR)
    end

    local page_path = Path:new(content_folder):joinpath(opts.path)
    local final_path = page_path

    if opts.page_is_dir ~= false then
        if page_path:exists() and not opts.force then
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

    write_to_file(final_path:absolute(), render_front_matter(opts.draft ~= false))

    if opts.open ~= false then
        vim.cmd('e ' .. final_path:absolute())
        put_cursor_at_title()
    end
end

M.serve '/home/sam/projects/writing/slowcoder.org/'
return M
