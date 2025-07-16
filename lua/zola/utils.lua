local M = {}
function M._merge_tables(...)
    local result = {}

    local tables = { ... }
    -- Iterate in reverse so earlier tables overwrite later ones
    for i = #tables, 1, -1 do
        local t = tables[i]
        for k, v in pairs(t) do
            result[k] = v
        end
    end

    return result
end
--- Strip trailing slashes from a path safely.
---@param path string
---@return string
function M._strip_trailing_slash(path)
    if path == '/' then
        return path
    end
    local stripped = path:gsub('/*$', '')
    return stripped
end

--- Run an asynchronous job with error checking.
---@param cmd string[]
---@param opts table
---@return integer job_id
function M._run_job(cmd, opts)
    local job_id = vim.fn.jobstart(cmd, opts)
    if job_id <= 0 then
        vim.notify('Failed to start job: ' .. table.concat(cmd, ' '), vim.log.levels.ERROR)
    end
    return job_id
end

--- Write content to file at given path.
---@param path string
---@param content string
function M._write_to_file(path, content)
    local fd, err = vim.uv.fs_open(path, 'w', 420) -- permission 0644
    if not fd then
        return vim.notify('Failed to open file: ' .. err, vim.log.levels.ERROR)
    end

    local ok, write_err = vim.uv.fs_write(fd, content, -1)
    vim.uv.fs_close(fd)
    if not ok then
        vim.notify('Failed to write file: ' .. write_err, vim.log.levels.ERROR)
    end
end

return M
