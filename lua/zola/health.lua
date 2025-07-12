local Path = require 'plenary.path'
local M = {}

function M._check_common_opts(opts)
    if opts == nil then
        return
    end

    if opts.root then
        local path = Path:new(opts.root)
        if not path.exists() then
            vim.health.error 'site root was defined but does not exist'
        else
            vim.health.ok 'site root file was found at configured path'
        end
    end

    if opts.config_file_path then
        local path = Path:new(opts.config_file_path)
        if not path.exists() then
            vim.health.error 'config_file_path was defined but does not exist'
        else
            vim.health.ok 'config file was found at configured path'
        end
    end

    return true
end

function M._check_build_opts(opts)
    if opts == nil then
        return
    end

    return true
end

function M._check_serve_opts(opts)
    if opts == nil then
        return
    end

    return true
end

function M._check_check_opts(opts)
    if opts == nil then
        return
    end

    return true
end

M.check = function()
    vim.health.start 'Installation'
    -- make sure setup function parameters are ok
    if vim.fn.executable 'zola' then
        -- Run the `zola --version` command and capture its output
        local handle = io.popen 'zola --version'
        local result = handle:read '*a'
        handle:close()

        -- Trim leading/trailing whitespace
        result = result:gsub('^%s+', ''):gsub('%s+$', '')

        -- Remove "zola" from the beginning
        local version = result:gsub('^zola%s+', '')
        vim.health.ok('binary is correctly installed (version ' .. version .. ')')
    else
        vim.health.err 'binary not found'
    end
    vim.health.start 'config'

    M._check_common_opts(M.config.common)
    M._check_build_opts(M.config.build)
    M._check_serve_opts(M.config.serve)
    M._check_check_opts(M.config.check)
end

return M
