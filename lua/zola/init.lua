local Path = require 'plenary.path'
local ERROR = vim.log.levels.ERROR
local WARN = vim.log.levels.WARN
local INFO = vim.log.levels.INFO
local M = {}

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
    local project_root = root or vim.fn.getcwd()
    project_root = Path:new(project_root)
    print(project_root:joinpath 'config.toml')
    if project_root:joinpath('config.toml'):exists() then
        return project_root:joinpath 'config.toml'
    else
        return nil
    end
end

function M._discover_content_folder(root)
    local project_root = root or vim.fn.getcwd()
    project_root = Path:new(project_root)
    if project_root:joinpath('content'):exists() then
        return project_root:joinpath 'content'
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
---
--- Create a file `_index.md` with `+++\n+++` content in the given directory
---@param dir string: The target directory path
local function create_section_index_md(dir, transparent, draft, taxonomies)
    local uv = vim.uv
    local path = dir .. '/_index.md'
    local front_matter = '+++\n'

    if draft then
        front_matter = front_matter .. 'draft = true\n'
    end

    if transparent then
        front_matter = front_matter .. 'transparent = true\n'
    end

    if taxonomies ~= nil and #taxonomies > 0 then
        front_matter = front_matter .. '[taxonomies]\n'
        local list = {}
        for taxonomy, items in pairs(taxonomies) do
            for _, item in ipairs(items) do
                table.insert(list, item)
            end
            front_matter = front_matter .. taxonomy .. ' = [ "' .. table.concat(list, '", ")') .. '"]\n'
        end
    end

    front_matter = front_matter .. '+++\n'

    -- Open the file for writing (flags: "w" = write, mode: 438 = 0666 in octal)
    local fd, err = uv.fs_open(path, 'w', 420)
    if not fd then
        vim.notify('Failed to open file: ' .. err, vim.log.levels.ERROR)
        return
    end

    -- Write content to the file
    local success, write_err = uv.fs_write(fd, front_matter, -1)
    if not success then
        vim.notify('Failed to write file: ' .. write_err, vim.log.levels.ERROR)
        uv.fs_close(fd)
        return
    end

    -- Close the file
    uv.fs_close(fd)
    --vim.notify('_index.md created in ' .. dir, vim.log.levels.INFO)
end

function M.create_section(path, force, transparent)
    if path == nil then
        vim.notify('Path not specified', ERROR)
        return
    end

    --TODO: maybe make this configurable?
    local content_folder = M._discover_content_folder(vim.fn.getcwd())
    if content_folder == nil then
        vim.notify('Could not determine content folder. is your cwd set correctly?', ERROR)
        return
    end

    local full_section_path = Path:new(content_folder):joinpath(path)

    local uv = vim.uv
    if full_section_path:exists() and not force then
        vim.notify('Section already exists! exiting.', ERROR)
        return
    end

    if force and full_section_path:exists() then
        uv.fs_rmdir(full_section_path:absolute())
    end

    uv.fs_mkdir(full_section_path:absolute(), 493)
    create_section_index_md(full_section_path)
end

return M
