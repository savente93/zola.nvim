-- spec/front_matter_spec.lua

local content = require 'zola.content'

describe('front_matter module', function()
    describe('_render_front_matter', function()
        it('renders front matter with draft = true when draft is true', function()
            local result = content._render_front_matter(true)
            local date = os.date '%Y-%m-%d'
            local expected = table.concat({
                '+++',
                'title = ""',
                'date = ' .. date,
                'draft = true',
                '+++',
                '',
            }, '\n')
            assert.are.equal(expected, result)
        end)

        it('renders front matter without draft line when draft is nil', function()
            local result = content._render_front_matter(nil)
            local date = os.date '%Y-%m-%d'
            local expected = table.concat({
                '+++',
                'title = ""',
                'date = ' .. date,
                '+++',
                '',
            }, '\n')
            assert.are.equal(expected, result)
        end)

        it('renders front matter without draft line when draft is false', function()
            local result = content._render_front_matter(false)
            local date = os.date '%Y-%m-%d'
            local expected = table.concat({
                '+++',
                'title = ""',
                'date = ' .. date,
                '+++',
                '',
            }, '\n')
            assert.are.equal(expected, result)
        end)
    end)

    describe('_calculate_cursor_pos', function()
        it('returns row and col for title empty quotes', function()
            local lines = {
                '+++',
                'title = ""',
                'date = 2025-07-16',
                '+++',
            }
            local row, col = content._calculate_cursor_pos(lines)
            assert.are.equal(2, row)
            assert.is_true(col > 0)
        end)

        it('returns nil,nil if title line not found', function()
            local lines = {
                '+++',
                'no title here',
                '+++',
            }
            local row, col = content._calculate_cursor_pos(lines)
            assert.is_nil(row)
            assert.is_nil(col)
        end)

        it('returns nil,nil if title line does not have empty quotes', function()
            local lines = {
                '+++',
                'title = "something"',
                '+++',
            }
            local row, col = content._calculate_cursor_pos(lines)
            assert.is_nil(row)
            assert.is_nil(col)
        end)
    end)

    describe('_put_cursor_at_title', function()
        local original_vim

        before_each(function()
            original_vim = vim
            vim = {
                api = {
                    nvim_get_current_buf = function()
                        return 1
                    end,
                    nvim_buf_get_lines = function(_, _, _, _)
                        return {
                            '+++',
                            'title = ""',
                            '+++',
                        }
                    end,
                    nvim_win_set_cursor = function(_, pos)
                        vim._cursor_set = pos
                    end,
                    nvim_feedkeys = function(keys, mode, escape)
                        vim._feedkeys_called = { keys, mode, escape }
                    end,
                },
                notify = function(msg)
                    vim._notified = msg
                end,
            }
        end)

        after_each(function()
            vim = original_vim
        end)

        it('sets cursor to title quotes and enters insert mode', function()
            local success = content._put_cursor_at_title()
            assert.is_true(success)
            assert.is_not_nil(vim._cursor_set)
            assert.are.same('i', vim._feedkeys_called[1])
        end)

        it('notifies and returns false if title not found', function()
            vim.api.nvim_buf_get_lines = function(_, _, _, _)
                return { '+++', 'no title here', '+++' }
            end

            local success = content._put_cursor_at_title()
            assert.is_false(success)
            assert.is_not_nil(vim._notified)
        end)
    end)
end)
