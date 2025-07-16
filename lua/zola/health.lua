local ok = vim.health.ok
local error = vim.health.error
local warn = vim.health.warn

local M = {}

function M._check_build_opts(opts)
    vim.validate {
        opts = { opts, 'table' },
        force = { opts.force, 'boolean' },
        minify = { opts.minify, 'boolean' },
        drafts = { opts.drafts, 'boolean' },
    }

    for k, _ in pairs(opts) do
        if k ~= 'force' and k ~= 'minify' and k ~= 'drafts' then
            warn('Warning: Unknown key in build: ' .. k)
        end
    end

    ok 'Build config is valid'
end

function M._check_serve_opts(opts)
    vim.validate {
        opts = { opts, 'table' },
        force = { opts.force, 'boolean' },
        drafts = { opts.drafts, 'boolean' },
        open = { opts.open, 'boolean' },
        fast = { opts.fast, 'boolean' },
    }

    for k, _ in pairs(opts) do
        if not ({
            force = true,
            drafts = true,
            open = true,
            fast = true,
        })[k] then
            print('Warning: Unknown key in serve: ' .. k)
        end
    end

    ok 'Serve config is valid'
end

function M._check_check_opts(opts)
    vim.validate {
        opts = { opts, 'table' },
        drafts = { opts.drafts, 'boolean' },
        skip_external_links = { opts.skip_external_links, 'boolean' },
    }

    for k, _ in pairs(opts) do
        if k ~= 'drafts' and k ~= 'skip_external_links' then
            print('Warning: Unknown key in check: ' .. k)
        end
    end

    ok 'Check config is valid'
end

M.check = function()
    vim.health.start 'Installation'

    -- Check if zola is executable
    if vim.fn.executable 'zola' == 1 then
        local handle = io.popen 'zola --version'
        assert(handle ~= nil, "Zola binary found but couldn't determine version")

        local result = handle:read '*a'
        handle:close()

        -- Trim leading/trailing whitespace and extract version
        local version = result:gsub('^%s+', ''):gsub('%s+$', ''):gsub('^zola%s+', '')
        ok('binary is correctly installed (version ' .. version .. ')')
    else
        error 'Zola binary not found'
    end

    vim.health.start 'Config'

    local config = require('zola').config

    vim.validate {
        config = { config, 'table' },
    }

    M._check_build_opts(config.build)
    M._check_serve_opts(config.serve)
    M._check_check_opts(config.check)
end

return M
