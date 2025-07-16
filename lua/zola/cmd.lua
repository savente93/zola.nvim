local M = {}

function M._compute_check_args(args, check_config, common_config)
    local cmd = { 'zola' }
    local used_opts = require('zola.utils')._merge_tables(args, check_config, common_config)

    if used_opts.root then
        vim.list_extend(cmd, { '--root', used_opts.root })
    end

    table.insert(cmd, 'check')

    if used_opts.skip_external_links then
        table.insert(cmd, '--skip-external-links')
    end
    if used_opts.drafts then
        table.insert(cmd, '--drafts')
    end
    return cmd
end

function M._compute_serve_args(args, serve_config, common_config)
    local cmd = { 'zola' }
    local used_opts = require('zola.utils')._merge_tables(args, serve_config, common_config)

    if used_opts.root then
        vim.list_extend(cmd, { '--root', used_opts.root })
    end

    table.insert(cmd, 'serve')

    if used_opts.force then
        table.insert(cmd, '--force')
    end

    if used_opts.open then
        table.insert(cmd, '--open')
    end
    if used_opts.fast then
        table.insert(cmd, '--fast')
    end
    if used_opts.incl_drafts then
        table.insert(cmd, '--drafts')
    end
    if used_opts.output_dir then
        vim.list_extend(cmd, { '--output_dir', used_opts.output_dir })
    end
    return cmd
end

--- comput the
---@param args { root?: string, force?: boolean, draft?: boolean, open?: boolean, output_dir?: string}
---@return {}
function M._compute_build_args(args, build_config, common_config)
    local cmd = { 'zola' }
    local used_opts = require('zola.utils')._merge_tables(args, build_config, common_config)

    if used_opts.root then
        vim.list_extend(cmd, { '--root', used_opts.root })
    end

    table.insert(cmd, 'build')

    if used_opts.force then
        table.insert(cmd, '--force')
    end

    if used_opts.minify then
        table.insert(cmd, '--minify')
    end
    if used_opts.drafts then
        table.insert(cmd, '--drafts')
    end
    if used_opts.output_dir then
        vim.list_extend(cmd, { '--output_dir', used_opts.output_dir })
    end

    return cmd
end
function M._compute_create_page_args(args, create_page_config) end
function M._compute_create_section_args(args, create_page_config) end
return M
