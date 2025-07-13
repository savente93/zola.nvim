local Path = require 'plenary.path'
local uv = vim.uv
local ERROR = vim.log.levels.ERROR
local WARN = vim.log.levels.WARN
local INFO = vim.log.levels.INFO

---@class zola_plugin
local M = {}

-- Utility: strip trailing slashes safely
local function strip_trailing_slash(path)
    if path == '/' then
        return path
    end
    return path:gsub('/*$', '')
end

-- Utility: run a job with error checking
local function run_job(cmd, opts)
    local job_id = vim.fn.jobstart(cmd, opts)
    if job_id <= 0 then
        vim.notify('Failed to start job: ' .. table.concat(cmd, ' '), ERROR)
    end
    return job_id
end

-- Default config
M.config = {
    build = { force = false, minify = true, incl_drafts = false },
    serve = { force = false, incl_drafts = false, open = false, fast = false, no_port_append = false },
    check = { incl_drafts = false, skip_external_links = false },
}

function M.setup(user_config)
    M.config = vim.tbl_deep_extend('force', M.config, user_config or {})
end

function M._discover_config_file(root)
    local project_root = strip_trailing_slash(root or vim.fn.getcwd())
    local config_path = Path:new(project_root):joinpath 'config.toml'
    return config_path:exists() and config_path or nil
end

function M._discover_content_folder(root)
    local project_root = strip_trailing_slash(root or vim.fn.getcwd())
    local content_path = Path:new(project_root):joinpath 'content'
    return content_path:exists() and content_path or nil
end

function M._is_zola_site(root)
    return M._discover_config_file(root) and M._discover_content_folder(root)
end

function M.build(root, output_dir)
    local cmd = { 'zola', 'build' }
    local build_config = M.config.build

    if root then
        vim.list_extend(cmd, { '--root', root })
    end
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

function M.check(root)
    local cmd = { 'zola', 'check' }
    local check = M.config.check

    if root then
        vim.list_extend(cmd, { '--root', root })
    end
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
                vim.notify('[zola_plugin] Check succesfull', INFO)
            else
                vim.notify('[zola_plugin] Check failed with code' .. code, ERROR)
            end
        end,
    })
end

function M.serve(root, output_dir, port, extra_watch_path)
    local cmd = { 'zola', 'serve' }
    local serve_config = M.config.serve

    if root then
        vim.list_extend(cmd, { '--root', root })
    end
    if serve_config.force then
        table.insert(cmd, '--force')
    end

    if serve_config.no_port_append then
        table.insert(cmd, '--no-port-append')
    end

    if port then
        if serve_config.no_port_append then
            vim.notify('Port was specified, but so was --no-port-append. Ignoring port', vim.log.levels.WARN)
        else
            vim.list_extend(cmd, { '--port', port })
        end
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

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].filetype = 'zola-log'

    vim.cmd 'vsplit'
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)

    local function append_lines(lines)
        if vim.api.nvim_buf_is_valid(buf) then
            vim.bo[buf].modifiable = true
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
            vim.bo[buf].modifiable = false
        end
    end

    run_job(cmd, {
        stdout_buffered = false,
        stderr_buffered = false,
        on_stdout = function(_, data)
            vim.schedule(function()
                append_lines(data)
            end)
        end,
        on_stderr = function(_, data)
            vim.schedule(function()
                append_lines(data)
            end)
        end,
        on_exit = function(_, code)
            if code == 0 then
                vim.notify('[zola_plugin] Serve exited successfully!', INFO)
            else
                vim.notify('[zola_plugin] Serve exited unsuccessfully with code ' .. code, ERROR)
            end
        end,
    })

    vim.notify('Started zola serve', INFO)
end

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

local function write_to_file(path, content)
    local fd, err = uv.fs_open(path, 'w', 420) -- permisson 0644 in decimal
    if not fd then
        return vim.notify('Failed to open file: ' .. err, ERROR)
    end

    local ok, write_err = uv.fs_write(fd, content, -1)
    uv.fs_close(fd)
    if not ok then
        vim.notify('Failed to write file: ' .. write_err, ERROR)
    end
end

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
        section_path:rm { recursive = true }
    end
    uv.fs_mkdir(section_path:absolute(), 493) -- permission 0755  in decimal

    local final_path = section_path:joinpath '_index.md'
    write_to_file(final_path:absolute(), render_front_matter(opts.draft ~= false))

    if opts.open ~= false then
        vim.cmd('e ' .. final_path:absolute())
        put_cursor_at_title()
    end
end

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

return M
