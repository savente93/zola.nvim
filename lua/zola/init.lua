local Path = require 'plenary.path'
local ERROR = vim.log.levels.ERROR
local M = {}

local function strip_trailing_slash(path)
    return path:gsub('(.)/$', '%1')
end

M.config = {

    build = {
        force = false,
        minify = true,
        incl_drafts = false,
    },

    serve = {
        force = false,
        incl_drafts = false,
        open = false,
        fast = false,
        no_port_append = false,
    },

    check = {
        incl_drafts = false,
        skip_external_links = false,
    },
}

function M._discover_config_file(root)
    local project_root = strip_trailing_slash(root or vim.fn.getcwd())
    local expanded_root = Path:new(project_root):expand()
    local config_path = Path:new(expanded_root):joinpath 'config.toml'

    if Path:new(config_path):exists() then
        return config_path
    else
        return nil
    end
end

function M._discover_content_folder(root)
    local project_root = strip_trailing_slash(root or vim.fn.getcwd())

    local expanded_root = Path:new(project_root):expand()
    local content_path = Path:new(expanded_root):joinpath 'content'

    if content_path:exists() then
        return content_path
    else
        return nil
    end
end

function M._is_zola_site(root)
    return M._discover_config_file(root) ~= nil and M._discover_content_folder(root) ~= nil
end

function M.setup() end

function M.build(root, output_dir)
    local cmd = { 'zola', 'build' }
    if root then
        table.insert(cmd, '--root')
        table.insert(cmd, root)
    end

    local build_config = M.config.build

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
        table.insert(cmd, '--output_dir')
        table.insert(cmd, output_dir)
    end

    vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify('[Zola stdout]: ' .. line, vim.log.levels.WARN)
                end
            end
        end,
        on_stderr = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify('[Zola stderr]: ' .. line, vim.log.levels.WARN)
                end
            end
        end,
        on_exit = function()
            vim.notify('[zola_plugin] Site built successfully!', vim.log.levels.INFO)
        end,
    })
end

function M.serve(root, output_dir, port, extra_watch_path)
    -- TODO: possibly kill server when buffer closes, this should be configurable
    -- TODO: preserve color of zola serve
    -- TODO: make better user space commands for this
    -- TODO: make server stop user command
    -- TODO: make toggle serve window command
    -- TODO: make make split vs floating window configurable

    local job_id = nil
    local buf_handle = nil
    local win_handle = nil

    -- determine cmd options
    local cmd = { 'zola', 'serve' }
    if root then
        table.insert(cmd, '--root')
        table.insert(cmd, root)
    end

    local serve_config = M.config.serve

    if serve_config.force then
        table.insert(cmd, '--force')
    end

    if serve_config.no_port_append then
        if port then
            vim.notify('Both port and no_append_port were specified. disregarding port', vim.log.levels.WARN)
        else
            table.insert(cmd, '--no_port_append ')
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
        table.insert(cmd, '--output_dir')
        table.insert(cmd, output_dir)
    end

    if extra_watch_path then
        table.insert(cmd, '--extra-watch-path')
        table.insert(cmd, extra_watch_path)
    end

    -- setup buffer for output
    -- Create a new scratch buffer
    buf_handle = vim.api.nvim_create_buf(false, true) -- [listed=false, scratch=true]

    -- Make it non-modifiable and read-only
    vim.bo[buf_handle].modifiable = false
    vim.bo[buf_handle].bufhidden = 'wipe'
    vim.bo[buf_handle].buftype = 'nofile'
    vim.bo[buf_handle].filetype = 'zola-log'

    -- Open in a new vertical split window
    vim.cmd 'vsplit'
    win_handle = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win_handle, buf_handle)

    local function append_lines(lines)
        if not vim.api.nvim_buf_is_valid(buf_handle) then
            return
        end
        vim.bo[buf_handle].modifiable = true
        vim.api.nvim_buf_set_lines(buf_handle, -1, -1, false, lines)
        vim.bo[buf_handle].modifiable = false
    end
    -- Start the `zola serve` command
    job_id = vim.fn.jobstart({ 'zola', 'serve' }, {
        stdout_buffered = false,
        stderr_buffered = false,
        on_stdout = function(_, data, _)
            if data then
                append_lines(data)
            end
        end,
        on_stderr = function(_, data, _)
            if data then
                append_lines(data)
            end
        end,
        on_exit = function(_, code, _)
            append_lines { '', '-- zola serve exited with code ' .. code .. ' --' }

            -- Close the window if it still exists and is valid
            vim.schedule(function()
                if vim.api.nvim_win_is_valid(win_handle) then
                    vim.api.nvim_win_close(win_handle, true)
                end
            end)

            job_id = nil
        end,
    })

    if job_id <= 0 then
        vim.notify('Failed to start zola serve', vim.log.levels.ERROR)
        return
    end

    vim.notify('Started zola serve', vim.log.levels.INFO)
end

function M.check(root, output_dir)
    local cmd = { 'zola', 'check' }
    if root then
        table.insert(cmd, '--root')
        table.insert(cmd, root)
    end

    local check = M.config.check

    if check.skip_external_links then
        table.insert(cmd, '--skip-external-links')
    end

    if check.incl_drafts then
        table.insert(cmd, '--drafts')
    end

    vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify('[Zola stdout]: ' .. line, vim.log.levels.WARN)
                end
            end
        end,
        on_stderr = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    vim.notify('[Zola stderr]: ' .. line, vim.log.levels.WARN)
                end
            end
        end,
        on_exit = function()
            vim.notify('[zola_plugin] Site built successfully!', vim.log.levels.INFO)
        end,
    })
end

local function render_front_matter(draft)
    local front_matter = '+++\n'

    front_matter = front_matter .. 'title = ""\n'
    front_matter = front_matter .. 'date = ' .. os.date '%Y-%m-%d' .. '\n'

    if draft then
        front_matter = front_matter .. 'draft = true\n'
    end

    front_matter = front_matter .. '+++\n'

    return front_matter
end

local function write_to_file(path, content)
    local uv = vim.uv
    local fd, err = uv.fs_open(path, 'w', 420)

    if not fd then
        vim.notify('Failed to open file: ' .. err, vim.log.levels.ERROR)
        return
    end

    -- Write content to the file
    local success, write_err = uv.fs_write(fd, content, -1)
    if not success then
        vim.notify('Failed to write file: ' .. write_err, vim.log.levels.ERROR)
        uv.fs_close(fd)
        return
    end

    -- Close the file
    uv.fs_close(fd)
end

local function put_cursor_at_title()
    -- put the curos inbetween the quotes on the title = "" line
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    for i, line in ipairs(lines) do
        local start_col, _ = line:find 'title%s*=%s*""'
        if start_col then
            -- 2. Place the cursor between the quotes (i.e., after the = and space and opening quote)
            -- Line numbers are 0-indexed, columns are 0-indexed too
            local target_col = line:find '""' -- position of first quote
            if target_col then
                -- Move to between the quotes
                vim.api.nvim_win_set_cursor(0, { i, target_col })
                -- also put us in insert mode so we can add the title immediately
                vim.api.nvim_feedkeys('i', 'n', false)
            end
            break
        end
    end
end

function M.create_section(opts)
    local path = opts.path
    local root = opts.root or vim.fn.getcwd()
    local force = opts.force ~= false
    local open = opts.open ~= false
    local draft = opts.draft ~= false

    if path == nil then
        vim.notify('Path not specified', vim.log.levels.ERROR)
        return
    end

    local content_folder = M._discover_content_folder(root)

    if content_folder == nil then
        vim.notify('Could not determine content folder. Is your cwd set correctly?', vim.log.levels.ERROR)
        return
    end

    -- Ensure we expand content_folder correctly before joining
    local content_path = Path:new(Path:new(content_folder):expand())
    local full_section_path = content_path:joinpath(path)

    local uv = vim.uv

    if full_section_path:exists() and not force then
        vim.notify('Section already exists! Exiting.', vim.log.levels.ERROR)
        return
    end

    if force and full_section_path:exists() then
        uv.fs_rmdir(full_section_path:absolute())
    end

    uv.fs_mkdir(full_section_path:absolute(), 493) -- 493 = 0755 in decimal

    local final_path = full_section_path .. '/_index.md'
    local front_matter = render_front_matter(draft)
    write_to_file(final_path, front_matter)

    if open then
        vim.cmd('e ' .. final_path)
        put_cursor_at_title()
    end
end

function M.create_page(opts)
    local path = opts.path
    local root = opts.root or vim.fn.getcwd()
    local page_is_dir = opts.page_is_dir ~= false
    local force = opts.force ~= false
    local open = opts.open ~= false
    local draft = opts.draft ~= false

    if path == nil then
        vim.notify('Path not specified', vim.log.levels.ERROR)
        return
    end

    local content_folder = M._discover_content_folder(root)

    if content_folder == nil then
        vim.notify('Could not determine content folder. Is your cwd set correctly?', vim.log.levels.ERROR)
        return
    end

    -- Ensure we expand content_folder correctly before joining
    local content_path = Path:new(Path:new(content_folder):expand())

    -- not completely valid yet, as it can stil lbe either a dir or a file
    local page_path = content_path:joinpath(path)

    local uv = vim.uv
    if page_is_dir then
        -- curretnly page_path points to the dir
        if page_path:exists() then
            if not force then
                vim.notify('page dir already exists! exiting.', ERROR)
                return
            else
                uv.fs_unlink(page_path:absolute())
            end
        end
        uv.fs_mkdir(page_path:absolute(), 493)

        page_path = page_path:joinpath 'index.md'
    else
        if not page_path.filename:match '.md$' then
            page_path = page_path .. '.md'
        end

        page_path = Path:new(page_path)
    end

    vim.notify(page_path.filename, vim.log.levels.WARN)
    if page_path:exists() then
        if not force then
            vim.notify('page dir already exists! exiting.', ERROR)
            return
        else
            uv.fs_unlink(page_path:absolute())
        end
    end

    local front_matter = render_front_matter(draft)
    write_to_file(page_path.filename, front_matter)

    if open then
        vim.cmd('e ' .. page_path.filename)

        put_cursor_at_title()
    end
end

M.create_page {
    path = 'test_page',
    page_is_dir = true,
    root = '~/projects/writing/slowcoder.org/',
    draft = true,
    open = true,
}

return M
