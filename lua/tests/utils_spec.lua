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
end)
