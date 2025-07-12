local Path = require("plenary.path")
local M = {}

function M._check_common_opts(opts)
	if opts.root then
		local path = Path:new(opts.root)
		if not path.exists() then
			vim.health.error("site root was defined but does not exist")
		else
			vim.health.ok("site root file was found at configured path")
		end
	end

	if opts.config_file_path then
		local path = Path:new(opts.config_file_path)
		if not path.exists() then
			vim.health.error("config_file_path was defined but does not exist")
		else
			vim.health.ok("config file was found at configured path")
		end
	end

	return true
end

function M._check_build_opts(opts)
	return true
end

function M._check_serve_opts(opts)
	return true
end

function M._check_check_opts(opts)
	return true
end

M.check = function()
	vim.health.start("Zola")
	-- make sure setup function parameters are ok
	if vim.fn.executable("zola") then
		vim.health.ok("Zola " .. "is correctly installed")
	else
		vim.health.err("Zola binary not found")
	end

	M._check_common_opts()
	M._check_build_opts()
	M._check_serve_opts()
	M._check_check_opts()
end

return M
