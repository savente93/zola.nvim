vim.api.nvim_create_user_command('ZolaBuild', function(opts)
    local build_opts = {}

    -- opts.args is a string of all arguments
    -- Split it and add as keys with true value
    for word in opts.args:gmatch '%S+' do
        build_opts[word] = true
    end
    require('zola').build(build_opts)
end, {
    nargs = '?',
    desc = 'Build the Zola site',
    complete = function(_ArgLead, _CmdLine, _CursorPos)
        return { 'force', 'minify', 'drafts' }
    end,
})

vim.api.nvim_create_user_command('ZolaServe', function(opts)
    local serve_opts = {}

    for word in opts.args:gmatch '%S+' do
        serve_opts[word] = true
    end
    require('zola').serve(serve_opts)
end, {
    nargs = '?',
    desc = 'Serve a live preview of your Zola site',
    complete = function(_ArgLead, _CmdLine, _CursorPos)
        return { 'open', 'fast', 'drafts' }
    end,
})

vim.api.nvim_create_user_command('ZolaCheck', function(opts)
    local check_opts = {}

    for word in opts.args:gmatch '%S+' do
        check_opts[word] = true
    end
    require('zola').check(check_opts)
end, {
    nargs = '?',
    desc = 'Check your Zola site without building',
    complete = function(_ArgLead, _CmdLine, _CursorPos)
        return { 'skip_external_links', 'drafts' }
    end,
})

vim.api.nvim_create_user_command('ZolaCreatePage', function(opts)
    vim.ui.input({ prompt = 'Enter slug: ' }, function(result)
        if not result then
            print 'No slug provided'
            return
        end

        local page_opts = {}
        page_opts.slug = result

        for word in opts.args:gmatch '%S+' do
            page_opts[word] = true
        end

        require('zola').create_page(page_opts)
    end)
end, {
    nargs = '?',
    desc = 'Create a new zola page',
    complete = function(_ArgLead, _CmdLine, _CursorPos)
        return { 'force', 'draft', 'open', 'page_is_dir' }
    end,
})

vim.api.nvim_create_user_command('ZolaCreateSection', function(opts)
    vim.ui.input({ prompt = 'Enter slug: ' }, function(result)
        if not result then
            print 'No slug provided'
            return
        end

        local section_opts = {}
        section_opts.slug = result

        for word in opts.args:gmatch '%S+' do
            section_opts[word] = true
        end

        require('zola').create_section(section_opts)
    end)
end, {
    nargs = '?',
    desc = 'Create a new zola section',
    complete = function(_, _, _)
        return { 'force', 'draft', 'open', 'date' }
    end,
})
