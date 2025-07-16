local M = {}

--- Render default TOML front matter for new content.
---@param draft boolean|nil
---@return string
function M._render_front_matter(draft)
    local date = os.date '%Y-%m-%d'
    return table.concat({
        '+++',
        'title = ""',
        'date = ' .. date,
        draft and 'draft = true' or nil,
        '+++',
        '',
    }, '\n')
end

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

--- Put cursor inside empty title quotes in front matter.
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
