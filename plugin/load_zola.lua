vim.api.nvim_create_user_command('ZolaBuild', function(opts)
    local build_opts = {}
    for word in opts.args:gmatch '%S+' do
        local key, value = word:match '([^=]+)=([^=]+)'
        if key and value then
            -- Convert string "false"/"true" to boolean
            if value == 'false' then
                build_opts[key] = false
            elseif value == 'true' then
                build_opts[key] = true
            else
                build_opts[key] = value -- store raw string if not true/false
            end
        else
            -- No '=', treat as flag set to true
            build_opts[word] = true
        end
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
        local key, value = word:match '([^=]+)=([^=]+)'
        if key and value then
            -- Convert string "false"/"true" to boolean
            if value == 'false' then
                serve_opts[key] = false
            elseif value == 'true' then
                serve_opts[key] = true
            else
                serve_opts[key] = value -- store raw string if not true/false
            end
        else
            -- No '=', treat as flag set to true
            serve_opts[word] = true
        end
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
        local key, value = word:match '([^=]+)=([^=]+)'
        if key and value then
            -- Convert string "false"/"true" to boolean
            if value == 'false' then
                check_opts[key] = false
            elseif value == 'true' then
                check_opts[key] = true
            else
                check_opts[key] = value -- store raw string if not true/false
            end
        else
            -- No '=', treat as flag set to true
            check_opts[word] = true
        end
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
        for word in opts.args:gmatch '%S+' do
            local key, value = word:match '([^=]+)=([^=]+)'
            if key and value then
                -- Convert string "false"/"true" to boolean
                if value == 'false' then
                    page_opts[key] = false
                elseif value == 'true' then
                    page_opts[key] = true
                else
                    page_opts[key] = value -- store raw string if not true/false
                end
            else
                -- No '=', treat as flag set to true
                page_opts[word] = true
            end
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
        for word in opts.args:gmatch '%S+' do
            local key, value = word:match '([^=]+)=([^=]+)'
            if key and value then
                -- Convert string "false"/"true" to boolean
                if value == 'false' then
                    section_opts[key] = false
                elseif value == 'true' then
                    section_opts[key] = true
                else
                    section_opts[key] = value -- store raw string if not true/false
                end
            else
                -- No '=', treat as flag set to true
                section_opts[word] = true
            end
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
