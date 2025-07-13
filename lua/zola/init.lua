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

function M.serve(root) end
function M.check(root) end

return M
