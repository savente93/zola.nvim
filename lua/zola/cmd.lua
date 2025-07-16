local M = {}

--- Determine the correct commandine arguments taking precidence into account for `zola check`
---@param args {root?: string, skip_external_links?: boolean, drafts?: boolean} any arguments provided to the function call
---@param check_config {root?: string, skip_external_links?: boolean, drafts?: boolean} arguments provided in check user config
---@param common_config {root?: string} arguments proivded in common user config
---@return {root?: string, skip_external_links?: boolean, drafts?: boolean} -- the actual flags and arguments that shold be used
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

--- Determine the correct commandine arguments taking precidence into account for `zola serve`
---@param args {root?: string, force?: boolean, open?: boolean, fast?: boolean, drafts?: boolean, output_dir?: string, } any arguments provided to the function call
---@param serve_config  { force?: boolean, open?: boolean, fast?: boolean, drafts?: boolean, output_dir?: string, } arguments provided in check user config
---@param common_config  {root?: string} arguments proivded in common user config
---@return {root?: string, force?: boolean, open?: boolean, fast?: boolean, drafts?: boolean, output_dir?: string, } -- the actual flags and arguments that shold be used
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

--- Determine the correct commandine arguments taking precidence into account for `zola build`
---@param args {root?: string, force?: boolean, drafts?: boolean,output_dir?: string, minify?: boolean} any arguments provided to the function call
---@param build_config  {root?: string, force?: boolean, drafts?: boolean,output_dir?: string, minify?: boolean} arguments provided in build user config
---@param common_config  {root?: string} arguments proivded in common user config
---@return {root?: string, force?: boolean, drafts?: boolean,output_dir?: string, minify?: boolean} -- the actual flags and arguments that should be used
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

--- Determine the correct options taking precidence into account for creating new pages
---@param args {slug: string, root?: string, force?: boolean, draft?: boolean, open?: boolean, page_is_dir?:boolean, date?: boolean} any arguments provided to the function call
---@param create_page_config { root?: string, force?: boolean, draft?: boolean, open?: boolean, page_is_dir?:boolean, date?: boolean} arguments provided in the create_page user config
---@param common_config  {root?: string} arguments proivded in common user config
---@return {slug: string, root: string, force?: boolean, draft?: boolean, open?: boolean, page_is_dir?:boolean, date?: boolean} -- the actual arguments that shold be used
function M._compute_create_page_args(args, create_page_config, common_config)
    local used_opts = require('zola.utils')._merge_tables(args, create_page_config, common_config)

    if used_opts.root == nil then
        used_opts.root = vim.fn.getcwd()
    end

    return used_opts
end

--- Determine the correct options taking precidence into account for creating new sections
---@param args {slug: string, root?: string, force?: boolean, draft?: boolean, open?: boolean, date?: boolean} any arguments provided to the function call
---@param create_section_config {root?: string, force?: boolean, draft?: boolean, open?: boolean, date?: boolean} arguments provided in the create_section user config
---@param common_config  {root?: string} arguments proivded in common user config
---@return {slug: string, root?: string, force?: boolean, draft?: boolean, open?: boolean, date?: boolean} -- the actual flags and arguments that shold be used
function M._compute_create_section_args(args, create_section_config, common_config)
    local used_opts = require('zola.utils')._merge_tables(args, create_section_config, common_config)

    return used_opts
end
return M
