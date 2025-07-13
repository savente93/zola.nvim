local Path = require 'plenary.path'
local ok = vim.health.ok
local error = vim.health.error
local warn = vim.health.warn
local info = vim.health.info

local M = {}

function M._check_build_opts(opts)
    local valid = true

    if type(opts) ~= 'table' then
        error('build section must be a table, got ' .. type(opts))
        valid = false
    end

    if type(opts.force) ~= 'boolean' then
        error('build.force must be a boolean, got ' .. type(opts.force))
        valid = false
    end

    if type(opts.minify) ~= 'boolean' then
        error('build.minify must be a boolean, got ' .. type(opts.minify))
        valid = false
    end

    if type(opts.incl_drafts) ~= 'boolean' then
        error('build.incl_drafts must be a boolean, got ' .. type(opts.incl_drafts))
        valid = false
    end

    for k, _ in pairs(opts) do
        if k ~= 'force' and k ~= 'minify' and k ~= 'incl_drafts' then
            warn('Warning: Unknown key in build: ' .. k)
        end
    end

    if valid then
        ok 'Build config is valid'
    end
end

function M._check_serve_opts(opts)
    local valid = true
    if type(opts) ~= 'table' then
        error('serve section must be a table, got ' .. type(opts))
        valid = false
    end

    if type(opts.force) ~= 'boolean' then
        error('serve.force must be a boolean, got ' .. type(opts.force))
        valid = false
    end

    if type(opts.incl_drafts) ~= 'boolean' then
        error('serve.incl_drafts must be a boolean, got ' .. type(opts.incl_drafts))
        valid = false
    end

    if type(opts.open) ~= 'boolean' then
        error('serve.open must be a boolean, got ' .. type(opts.open))
        valid = false
    end

    if opts.store_html ~= nil and type(opts.store_html) ~= 'string' then
        error('serve.store_html must be a string or nil, got ' .. type(opts.store_html))
        valid = false
    end

    if type(opts.fast) ~= 'boolean' then
        error('serve.fast must be a boolean, got ' .. type(opts.fast))
        valid = false
    end

    if type(opts.no_port_append) ~= 'boolean' then
        error('serve.no_port_append must be a boolean, got ' .. type(opts.no_port_append))
        valid = false
    end

    for k, _ in pairs(opts) do
        if
            not ({
                force = true,
                incl_drafts = true,
                open = true,
                store_html = true,
                fast = true,
                no_port_append = true,
            })[k]
        then
            print('Warning: Unknown key in serve: ' .. k)
        end
    end
    if valid then
        ok 'Serve config is valid'
    end
end

function M._check_check_opts(opts)
    local valid = true
    if type(opts) ~= 'table' then
        error('check section must be a table, got ' .. type(opts))
        valid = false
    end

    if type(opts.incl_drafts) ~= 'boolean' then
        error('check.incl_drafts must be a boolean, got ' .. type(opts.incl_drafts))
        valid = false
    end

    if type(opts.skip_external_links) ~= 'boolean' then
        error('check.skip_external_links must be a boolean, got ' .. type(opts.skip_external_links))
        valid = false
    end

    for k, _ in pairs(opts) do
        if k ~= 'incl_drafts' and k ~= 'skip_external_links' then
            print('Warning: Unknown key in check: ' .. k)
        end
    end
    if valid then
        ok 'Check config is valid'
    end
end

M.check = function()
    vim.health.start 'Installation'
    local config = require('zola').config

    -- make sure setup function parameters are ok
    if vim.fn.executable 'zola' then
        -- Run the `zola --version` command and capture its output
        local handle = io.popen 'zola --version'
        if handle == nil then
            error "Zola bin was found but coudn't determine version"
            return
        end
        local result = handle:read '*a'
        handle:close()

        -- Trim leading/trailing whitespace
        result = result:gsub('^%s+', ''):gsub('%s+$', '')

        -- Remove "zola" from the beginning
        local version = result:gsub('^zola%s+', '')
        ok('binary is correctly installed (version ' .. version .. ')')
    else
        error 'binary not found'
    end

    local valid = true

    if type(config) ~= 'table' then
        error('Error: config must be a table or nil not ' .. type(config))
        return
    end

    vim.health.start 'Config'
    M._check_build_opts(config.build)
    M._check_serve_opts(config.serve)
    M._check_check_opts(config.check)
end

return M
