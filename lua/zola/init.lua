print 'loading zola.nvim'

local M = {}

M.config = {
    config_file_path = nil,
    root = nil,
    build_opts = {
        base_url = nil,
        output_dir = nil,
        force = false,
        minify = true,
        incl_drafts = false,
    },
    serve_opts = {
        interface = nil,
        port = nil,
        output_dir = nil,
        force = false,
        base_url = nil,
        incl_drafts = false,
        open = false,
        store_html = nil,
        fast = false,
        no_port_append = false,
        extra_watch_path = nil,
    },
    check_opts = {
        incl_drafts = false,
        skip_external_links = false,
    },
}

function M.setup() end

function M.build(root)
    if not M.config.zola_path then
        vim.notify('Zola binary not configured.', vim.log.levels.ERROR)
        return
    end

    local cmd = M.config.zola_path .. ' build'
    if root then
        cmd = cmd .. '--root ' .. root
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

-- M.setup()
-- M.build("/home/sam/projects/writng/slowcoder.org/")

return M
