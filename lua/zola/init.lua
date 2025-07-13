local Path = require 'plenary.path'
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
    if project_root:join('config.toml').exists() then
        return project_root
    else
        return nil
    end
end

function M._discover_content_folder(root)
    local project_root = root or vim.fn.getcwd()
    project_root = Path:new(project_root)
    if project_root:join('content').exists() then
        return project_root
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

return M
