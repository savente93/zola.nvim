-- spec/discovery_spec.lua

local discovery = require 'your_module.discovery' -- adjust path accordingly

describe('discovery module', function()
    local original_vim
    local fake_path

    before_each(function()
        original_vim = vim
        vim = {
            fn = {
                getcwd = function()
                    return '/fake/current/dir'
                end,
            },
        }

        -- Fake Path class with :new and :joinpath returning itself, :exists returning controlled boolean
        fake_path = {
            new_called_with = nil,
            joinpath_called_with = nil,
            exists_returns = true,
            new = function(self, path)
                self.new_called_with = path
                return self
            end,
            joinpath = function(self, sub)
                self.joinpath_called_with = sub
                return self
            end,
            exists = function(self)
                return self.exists_returns
            end,
        }

        package.loaded['plenary.path'] = {
            new = function(path)
                return fake_path:new(path)
            end,
        }

        package.loaded['zola.utils'] = {
            strip_trailing_slash = function(path)
                return path:gsub('/*$', '')
            end,
        }
    end)

    after_each(function()
        vim = original_vim
    end)

    describe('_discover_config_file', function()
        it('returns Path object when config.toml exists', function()
            fake_path.exists_returns = true
            local result = discovery._discover_config_file '/my/root'
            assert.is_not_nil(result)
            assert.are.equal('/my/root', fake_path.new_called_with)
            assert.are.equal('config.toml', fake_path.joinpath_called_with)
        end)

        it('returns nil when config.toml does not exist', function()
            fake_path.exists_returns = false
            local result = discovery._discover_config_file '/my/root'
            assert.is_nil(result)
        end)

        it('uses vim.fn.getcwd when root is nil', function()
            fake_path.exists_returns = true
            local result = discovery._discover_config_file(nil)
            assert.are.equal('/fake/current/dir', fake_path.new_called_with)
            assert.is_not_nil(result)
        end)
    end)

    describe('_discover_content_folder', function()
        it('returns Path object when content folder exists', function()
            fake_path.exists_returns = true
            local result = discovery._discover_content_folder '/my/root'
            assert.is_not_nil(result)
            assert.are.equal('/my/root', fake_path.new_called_with)
            assert.are.equal('content', fake_path.joinpath_called_with)
        end)

        it('returns nil when content folder does not exist', function()
            fake_path.exists_returns = false
            local result = discovery._discover_content_folder '/my/root'
            assert.is_nil(result)
        end)

        it('uses vim.fn.getcwd when root is nil', function()
            fake_path.exists_returns = true
            local result = discovery._discover_content_folder(nil)
            assert.are.equal('/fake/current/dir', fake_path.new_called_with)
            assert.is_not_nil(result)
        end)
    end)
end)
