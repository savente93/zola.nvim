-- spec/util_spec.lua

local util = require 'zola.utils'

describe('zola.utils', function()
    describe('_merge_tables', function()
        it('merges multiple tables with earlier tables taking precedence', function()
            local t1 = { a = 1, b = 2 }
            local t2 = { b = 3, c = 4 }
            local t3 = { d = 5, c = 6 }

            local result = util._merge_tables(t1, t2, t3)
            assert.are.same({
                a = 1,
                b = 2, -- from t1 overwrites t2
                c = 4, -- from t2 overwrites t3
                d = 5,
            }, result)
        end)

        it('returns empty table when called with no arguments', function()
            local result = util._merge_tables()
            assert.are.same({}, result)
        end)

        it('works with single table argument', function()
            local result = util._merge_tables { x = 42 }
            assert.are.same({ x = 42 }, result)
        end)
    end)

    describe('_strip_trailing_slash', function()
        it('removes trailing slashes', function()
            assert.are.same('path/to/dir', util._strip_trailing_slash 'path/to/dir/')
            assert.are.same('path/to/dir', util._strip_trailing_slash 'path/to/dir///')
        end)

        it('returns root slash unchanged', function()
            assert.are.same('/', util._strip_trailing_slash '/')
        end)

        it('returns unchanged if no trailing slash', function()
            assert.are.same('dir', util._strip_trailing_slash 'dir')
        end)
    end)

    describe('_run_job', function()
        before_each(function()
            _G.vim = _G.vim or {}
            vim.fn = vim.fn or {}
            vim.notify = vim.notify or function() end
        end)

        describe('_write_to_file', function()
            local original_uv

            before_each(function()
                original_uv = vim.uv
                vim.uv = {
                    fs_open = function(_, _, _)
                        return 1
                    end,
                    fs_write = function(_, content, _)
                        assert.are.equal('content', content)
                        return true
                    end,
                    fs_close = function(_) end,
                }
                vim.notify = function() end
            end)

            after_each(function()
                vim.uv = original_uv
            end)

            it('writes content to file successfully', function()
                util._write_to_file('test.txt', 'content')
            end)

            it('notifies on failure to open file', function()
                vim.uv.fs_open = function(_, _, _)
                    return nil, 'some error'
                end

                local notified = false
                vim.notify = function(msg, level)
                    notified = true
                    assert.is.truthy(msg:match 'Failed to open file')
                    assert.are.equal(vim.log.levels.ERROR, level)
                end

                util._write_to_file('fail.txt', 'content')
                assert.is_true(notified)
            end)

            it('notifies on failure to write file', function()
                vim.uv.fs_write = function(_, _, _)
                    return nil, 'write error'
                end

                local notified = false
                vim.notify = function(msg, level)
                    notified = true
                    assert.is.truthy(msg:match 'Failed to write file')
                    assert.are.equal(vim.log.levels.ERROR, level)
                end

                util._write_to_file('failwrite.txt', 'content')
                assert.is_true(notified)
            end)
        end)
    end)
end)
