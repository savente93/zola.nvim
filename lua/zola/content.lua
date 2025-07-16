local M = {}

--- Render default TOML front matter for new content.
---@param draft boolean|nil should the content be maked as drafed
---@return string a string containing the front matter incl seperators to include in zola content files
function M._render_front_matter(draft)
    local date = os.date '%Y-%m-%d'
    local lines = {
        '+++',
        'title = ""',
        'date = ' .. date,
    }
    if draft then
        table.insert(lines, 'draft = true')
    end
    vim.list_extend(lines, { '+++', '' })
    return table.concat(lines, '\n')
end

--- Determine the coordinates to put the cursor at so the user can fill otu the title in the front matter
---@param lines string[] the text of the buffer, typically includes onlyt the front matter
---@return integer|nil, integer|nil
function M._calculate_cursor_pos(lines)
    for i, line in ipairs(lines) do
        local target_col = line:find 'title%s*=%s*""'
        if target_col then
            local quote_col = line:find '""'
            if quote_col then
                return i, quote_col
            end
        end
    end

    return nil, nil
end

--- Put cursor inside empty title quotes in front matter of current buffer.
---@return boolean whether operation was successful
function M._put_cursor_at_title()
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local row, col = M._calculate_cursor_pos(lines)
    if row == nil or col == nil then
        vim.notify 'Could not determine cursor place'
        return false
    else
        vim.api.nvim_win_set_cursor(0, { row, col })
        vim.api.nvim_feedkeys('i', 'n', false)
        return true
    end
end

return M
