-- spec/compute_check_args_spec.lua

local M = require 'zola.cmd' -- replace with your actual module path

describe('_compute_check_args', function()
    it('returns base command when no options are set', function()
        local cmd = M._compute_check_args({}, {}, {})
        assert.are.same({ 'zola', 'check' }, cmd)
    end)

    it('includes --root when root is set in args', function()
        local cmd = M._compute_check_args({ root = '/from/args' }, {}, {})
        assert.are.same({ 'zola', '--root', '/from/args', 'check' }, cmd)
    end)

    it('uses root from check_config if not in args', function()
        local cmd = M._compute_check_args({}, { root = '/from/check_config' }, {})
        assert.are.same({ 'zola', '--root', '/from/check_config', 'check' }, cmd)
    end)

    it('uses root from common_config if not in args or check_config', function()
        local cmd = M._compute_check_args({}, {}, { root = '/from/common_config' })
        assert.are.same({ 'zola', '--root', '/from/common_config', 'check' }, cmd)
    end)

    it('includes --skip-external-links when set', function()
        local cmd = M._compute_check_args({ skip_external_links = true }, {}, {})
        assert.are.same({ 'zola', 'check', '--skip-external-links' }, cmd)
    end)

    it('includes --drafts when set', function()
        local cmd = M._compute_check_args({ drafts = true }, {}, {})
        assert.are.same({ 'zola', 'check', '--drafts' }, cmd)
    end)

    it('includes all options when all are set from different configs', function()
        local cmd = M._compute_check_args({ drafts = true }, { skip_external_links = true }, { root = '/from/common_config' })
        assert.are.same({
            'zola',
            '--root',
            '/from/common_config',
            'check',
            '--skip-external-links',
            '--drafts',
        }, cmd)
    end)

    it('prioritises earlier tables when merging', function()
        local cmd = M._compute_check_args(
            { root = '/args', drafts = true },
            { root = '/check_config', skip_external_links = true },
            { root = '/common_config' }
        )
        -- args.root takes precedence
        assert.are.same({
            'zola',
            '--root',
            '/args',
            'check',
            '--skip-external-links',
            '--drafts',
        }, cmd)
    end)
end)

describe('_compute_build_args', function()
    it('returns base build command when no options are set', function()
        local cmd = M._compute_build_args({}, {}, {})
        assert.are.same({ 'zola', 'build' }, cmd)
    end)

    it('includes --root when set in args', function()
        local cmd = M._compute_build_args({ root = '/from/args' }, {}, {})
        assert.are.same({ 'zola', '--root', '/from/args', 'build' }, cmd)
    end)

    it('uses root from build_config if not in args', function()
        local cmd = M._compute_build_args({}, { root = '/from/build_config' }, {})
        assert.are.same({ 'zola', '--root', '/from/build_config', 'build' }, cmd)
    end)

    it('uses root from common_config if not in args or build_config', function()
        local cmd = M._compute_build_args({}, {}, { root = '/from/common_config' })
        assert.are.same({ 'zola', '--root', '/from/common_config', 'build' }, cmd)
    end)

    it('includes --force when set', function()
        local cmd = M._compute_build_args({ force = true }, {}, {})
        assert.are.same({ 'zola', 'build', '--force' }, cmd)
    end)

    it('includes --minify when set', function()
        local cmd = M._compute_build_args({ minify = true }, {}, {})
        assert.are.same({ 'zola', 'build', '--minify' }, cmd)
    end)

    it('includes --drafts when set', function()
        local cmd = M._compute_build_args({ drafts = true }, {}, {})
        assert.are.same({ 'zola', 'build', '--drafts' }, cmd)
    end)

    it('includes --output-dir when set', function()
        local cmd = M._compute_build_args({ output_dir = 'dist' }, {}, {})
        assert.are.same({ 'zola', 'build', '--output-dir', 'dist' }, cmd)
    end)

    it('includes all options when all are set from different configs', function()
        local cmd = M._compute_build_args({ drafts = true }, { force = true, minify = true }, { root = '/from/common_config', output_dir = 'out' })
        assert.are.same({
            'zola',
            '--root',
            '/from/common_config',
            'build',
            '--force',
            '--minify',
            '--drafts',
            '--output-dir',
            'out',
        }, cmd)
    end)

    it('prioritises earlier tables when merging', function()
        local cmd = M._compute_build_args(
            { root = '/args', output_dir = 'args_out', drafts = true },
            { root = '/build_config', output_dir = 'build_out', force = true },
            { root = '/common_config', output_dir = 'common_out', minify = true }
        )
        assert.are.same({
            'zola',
            '--root',
            '/args',
            'build',
            '--force',
            '--minify',
            '--drafts',
            '--output-dir',
            'args_out',
        }, cmd)
    end)
end)

describe('_compute_serve_args', function()
    it('returns base serve command when no options are set', function()
        local cmd = M._compute_serve_args({}, {}, {})
        assert.are.same({ 'zola', 'serve' }, cmd)
    end)

    it('includes --root when set in args', function()
        local cmd = M._compute_serve_args({ root = '/from/args' }, {}, {})
        assert.are.same({ 'zola', '--root', '/from/args', 'serve' }, cmd)
    end)

    it('uses root from serve_config if not in args', function()
        local cmd = M._compute_serve_args({}, { root = '/from/serve_config' }, {})
        assert.are.same({ 'zola', '--root', '/from/serve_config', 'serve' }, cmd)
    end)

    it('uses root from common_config if not in args or serve_config', function()
        local cmd = M._compute_serve_args({}, {}, { root = '/from/common_config' })
        assert.are.same({ 'zola', '--root', '/from/common_config', 'serve' }, cmd)
    end)

    it('includes --force when set', function()
        local cmd = M._compute_serve_args({ force = true }, {}, {})
        assert.are.same({ 'zola', 'serve', '--force' }, cmd)
    end)

    it('includes --open when set', function()
        local cmd = M._compute_serve_args({ open = true }, {}, {})
        assert.are.same({ 'zola', 'serve', '--open' }, cmd)
    end)

    it('includes --fast when set', function()
        local cmd = M._compute_serve_args({ fast = true }, {}, {})
        assert.are.same({ 'zola', 'serve', '--fast' }, cmd)
    end)

    it('includes --drafts when incl_drafts is set', function()
        local cmd = M._compute_serve_args({ incl_drafts = true }, {}, {})
        assert.are.same({ 'zola', 'serve', '--drafts' }, cmd)
    end)

    it('includes --output-dir when set', function()
        local cmd = M._compute_serve_args({ output_dir = 'public' }, {}, {})
        assert.are.same({ 'zola', 'serve', '--output-dir', 'public' }, cmd)
    end)

    it('includes all options when all are set from different configs', function()
        local cmd = M._compute_serve_args(
            { incl_drafts = true, open = true },
            { force = true, fast = true },
            { root = '/from/common_config', output_dir = 'out' }
        )
        assert.are.same({
            'zola',
            '--root',
            '/from/common_config',
            'serve',
            '--force',
            '--open',
            '--fast',
            '--drafts',
            '--output-dir',
            'out',
        }, cmd)
    end)

    it('prioritises earlier tables when merging', function()
        local cmd = M._compute_serve_args(
            { root = '/args', output_dir = 'args_out', incl_drafts = true },
            { root = '/serve_config', output_dir = 'serve_out', open = true },
            { root = '/common_config', output_dir = 'common_out', fast = true, force = true }
        )
        assert.are.same({
            'zola',
            '--root',
            '/args',
            'serve',
            '--force',
            '--open',
            '--fast',
            '--drafts',
            '--output-dir',
            'args_out',
        }, cmd)
    end)
end)
