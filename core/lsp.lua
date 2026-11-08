-- Setup for lsp-zero
local lsp_zero = require('lsp-zero')

-- lsp_attach is where you enable features that only work
-- if there is a language server active in the file
local lsp_attach = function(client, bufnr)
	local opts = { buffer = bufnr }
	vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
	vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
	vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
	vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
	vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
	vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
	vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
	vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
	vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({ async = true })<cr>', opts)
	vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
end

lsp_zero.extend_lspconfig({
	sign_text = true,
	lsp_attach = lsp_attach,
	capabilities = require('cmp_nvim_lsp').default_capabilities(),
})

require('mason').setup({})
-- NOTE: `ensure_installed` belongs here (mason-lspconfig), not in
-- mason.nvim's setup. mason.nvim itself has no `ensure_installed` option,
-- and packer ignores the `opts` key anyway (that's a lazy.nvim thing),
-- which is why nothing was ever auto-installed.
require('mason-lspconfig').setup({
	ensure_installed = { "clangd", "pyright" },
	handlers = {
		function(server_name)
			-- clangd/pyright are configured explicitly below (0.12-style
			-- root_markers); letting this generic handler also set them up
			-- would merge the legacy lspconfig defaults back over our config.
			if server_name == "clangd" or server_name == "pyright" then
				return
			end
			require('lspconfig')[server_name].setup({
				on_attach = lsp_attach,
			})
		end,
	},
})

-- DAP binaries (codelldb) are NOT lsp servers, so mason-lspconfig can't
-- install them. mason-tool-installer handles those.
pcall(function()
	require('mason-tool-installer').setup({
		ensure_installed = { "codelldb" },
		auto_update = false,
		run_on_start = true,
	})
end)

-- Explicit clangd setup for C/C++. The generic handler above also covers
-- clangd once installed, but this gives us macOS-friendly flags, proper
-- root detection, and capabilities wired to nvim-cmp (autocomplete).
local clangd_cmd = { "clangd" }
-- Prefer the Mason-installed clangd if present, else fall back to system.
do
	-- Mason symlinks binaries to <data>/mason/bin/ (version-proof, unlike
	-- packages/clangd/clangd_<ver>/bin/clangd which changes per release).
	local mason_clangd = vim.fn.stdpath("data") .. "/mason/bin/clangd"
	if vim.fn.executable(mason_clangd) == 1 then
		clangd_cmd = { mason_clangd }
	end
end

local clangd_config = {
	on_attach = lsp_attach,
	capabilities = require('cmp_nvim_lsp').default_capabilities(),
	cmd = vim.list_extend(vim.deepcopy(clangd_cmd), {
		"--background-index",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders",
		"--fallback-style=llvm",
	}),
	-- Nvim 0.11+ resolves the project root from `root_markers` (upward
	-- search via vim.fs.root). A legacy `root_dir(fname) -> string` function
	-- is NOT called anymore -- the new signature is
	-- `root_dir(bufnr, on_dir)` and must invoke the `on_dir` callback, so an
	-- old-style function silently prevents the client from ever starting
	-- ("Enabled Configurations" shows clangd but "No active clients").
	root_markers = {
		"compile_commands.json", "compile_flags.txt",
		"CMakeLists.txt", "Makefile",
		".clangd", ".clang-tidy", ".clang-format", ".git",
	},
}

-- vim.lsp.config is the non-deprecated API on Nvim 0.11+. lspconfig's
-- `setup()` still works but warns. Support both.
if vim.lsp and vim.lsp.config then
	vim.lsp.config('clangd', clangd_config)
	vim.lsp.enable('clangd')
else
	require("lspconfig").clangd.setup(clangd_config)
end

local pyright_config = {
	on_attach = lsp_attach,
	capabilities = require('cmp_nvim_lsp').default_capabilities(),
	-- Same 0.11+ note as clangd above: declarative markers, not a
	-- legacy root_dir function.
	root_markers = {
		"pyrightconfig.json", "pyproject.toml",
		"setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git",
	},
}

if vim.lsp and vim.lsp.config then
	vim.lsp.config('pyright', pyright_config)
	vim.lsp.enable('pyright')
else
	require("lspconfig").pyright.setup(pyright_config)
end

vim.diagnostic.config({})

-- Setup cmp with lsp-zero
local icons = {
	Text = "",
	File = "",
	Variable = "",
	Snippet = "",
	Module = "",
	Class = "",
	Keyword = "",
	Function = "󰊕",
	Method = "󰊕",
	Codeium = "🤖",
	Field = "",
	Interface = "",
	Constant = "",
	Property = "",
}

local function border(hl_name)
	return {
		{ "╭", hl_name },
		{ "─", hl_name },
		{ "╮", hl_name },
		{ "│", hl_name },
		{ "╯", hl_name },
		{ "─", hl_name },
		{ "╰", hl_name },
		{ "│", hl_name },
	}
end

local cmp = require('cmp')

cmp.setup({
	window = {
		completion = cmp.config.window.bordered({
			winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuThumb,Search:None"
		}),
		documentation = cmp.config.window.bordered({
			border = border "CmpDocBorder",
			winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuThumb,Search:None"
		}),
	},

	formatting = {
		fields = {"abbr", "kind"},
		format = function(_, vim_item)
			vim_item.kind = (icons[vim_item.kind] or "?") .. " " .. vim_item.kind
			return vim_item
		end,
	},

	sources = {
		{ name = "codeium", max_item_count = 40 },
		{ name = 'nvim_lsp', max_item_count = 40 },
		{ name = "luasnip", max_item_count = 40 },
		{ name = 'buffer', max_item_count = 20 },
		{ name = 'path', max_item_count = 20 },
	},

	mapping = {
		['<CR>'] = cmp.mapping.confirm({ select = false }),
		['<C-e>'] = cmp.mapping.abort(),
		['<Up>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),
		['<Down>'] = cmp.mapping.select_next_item({ behavior = 'select' }),
		['<C-p>'] = cmp.mapping(function()
			if cmp.visible() then
				cmp.select_prev_item({ behavior = 'insert' })
			else
				cmp.complete()
			end
		end),
		['<C-n>'] = cmp.mapping(function()
			if cmp.visible() then
				cmp.select_next_item({ behavior = 'insert' })
			else
				cmp.complete()
			end
		end),
	},

	snippet = {
		expand = function(args)
			require('luasnip').lsp_expand(args.body)
		end,
	},
})

-- Setup dap
local dap = require('dap')
require('dapui').setup()
vim.fn.sign_define('DapBreakpoint', { text = '⭕', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '→', texthl = '', linehl = '', numhl = '' })

-- Auto-open/close dap-ui with a debug session.
do
	local ok_ui, dapui = pcall(require, 'dapui')
	if ok_ui then
		dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
		dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
		dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
	end
	do
		local ok_vt, vt = pcall(require, 'nvim-dap-virtual-text')
		if ok_vt then pcall(vt.setup) end
	end
end

-- Setup Python3 Debugger (auto-detect, old hardcoded 3.12 path no longer exists)
do
	local py = vim.fn.exepath("python3")
	if py ~= "" then
		local ok_dp, dap_python = pcall(require, 'dap-python')
		if ok_dp then pcall(dap_python.setup, py) end
	end
end

-- Setup C/C++ Debugger
-- (local dap already required above)

-- codelldb's binary lives at <install>/extension/adapter/codelldb, NOT
-- <install>/codelldb (the old path in this config). Resolve it robustly.
local function codelldb_path()
	local ok, registry = pcall(require, "mason-registry")
	if ok then
		local ok_pkg, pkg = pcall(registry.get_package, "codelldb")
		if ok_pkg and pkg:is_installed() then
			local candidate = pkg:get_install_path() .. "/extension/adapter/codelldb"
			if vim.fn.executable(candidate) == 1 then
				return candidate
			end
		end
	end
	if vim.fn.executable("codelldb") == 1 then
		return vim.fn.exepath("codelldb")
	end
	return nil
end

local codelldb_bin = codelldb_path()
if codelldb_bin then
	dap.adapters.codelldb = {
	  type = 'server',
	  port = "${port}",
	  executable = {
	    command = codelldb_bin,
	    args = {"--port", "${port}"},
	  }
	}
else
	vim.notify(
		"codelldb not found. Install it with :MasonInstall codelldb (then restart Neovim). C/C++ debugging will not work until then.",
		vim.log.levels.WARN
	)
end

-- Define the DAP configuration for your application
dap.configurations.cpp = {
  {
    name = "Launch (prompt for executable)",
    type = "codelldb",  -- the type of your adapter
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')  -- Prompt for the executable when starting
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = {},
  },
  {
    name = "Launch current file (g++ -g, then debug)",
    type = "codelldb",
    request = "launch",
    program = function()
      -- Compile the current file with debug symbols, then debug the output.
      local src = vim.fn.expand('%:p')
      local out = '/tmp/nvim-dbg-' .. vim.fn.expand('%:t:r')
      local cmd = string.format("g++ -std=c++17 -g '%s' -o '%s'", src, out)
      vim.notify("Compiling: " .. cmd)
      local rc = os.execute(cmd)
      if rc ~= 0 and rc ~= true then
        vim.notify("Compile failed, check :messages", vim.log.levels.ERROR)
        return out -- still return so codelldb shows a useful error
      end
      return out
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = {},
  },
}

dap.configurations.c = dap.configurations.cpp

-- Standard DAP stepping keys (your <C-b>/<C-d>/<C-q> maps in keymaps.lua still work).
vim.keymap.set('n', '<F5>', function() require('dap').continue() end, { desc = 'DAP continue' })
vim.keymap.set('n', '<F10>', function() require('dap').step_over() end, { desc = 'DAP step over' })
vim.keymap.set('n', '<F11>', function() require('dap').step_into() end, { desc = 'DAP step into' })
vim.keymap.set('n', '<F12>', function() require('dap').step_out() end, { desc = 'DAP step out' })

vim.cmd("set clipboard+=unnamed")
