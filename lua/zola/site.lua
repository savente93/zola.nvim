local M = {}
--- Discover Zola config.toml in project root.
---@param root string|nil, the path to search. cwd will be used if nil
---@return Path|nil the path of the config.toml if found, nil otherwise
function M._discover_config_file(root)
    local utils = require 'zola.utils'
    local Path = require 'plenary.path'
    local project_root = utils.strip_trailing_slash(root or vim.fn.getcwd())
    local config_path = Path:new(project_root):joinpath 'config.toml'
    return config_path:exists() and config_path or nil
end

--- Discover Zola content folder in project root.
---@param root string|nil, the path to search. cwd will be used if nil
---@return Path|nil the path of the content folder if found, nil otherwise
function M._discover_content_folder(root)
    local utils = require 'zola.utils'
    local Path = require 'plenary.path'
    local project_root = utils.strip_trailing_slash(root or vim.fn.getcwd())
    local content_path = Path:new(project_root):joinpath 'content'
    return content_path:exists() and content_path or nil
end

return M
