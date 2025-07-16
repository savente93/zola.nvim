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
end)
