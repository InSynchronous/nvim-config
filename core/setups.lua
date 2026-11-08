require('ibl').setup({
  indent = {
	char = '▏',
  },
  scope = {
	show_start = false,
	show_end = false,
  },
})
require("nvim-tree").setup()
require('lualine').setup()
require("bufferline").setup {
	options = {
		separator_style = "thick",
		diagnostics = "nvim_lsp",
		mode = 'buffers',
		hover = {
			enabled = true,
			delay = 200,
			reveal = {'close'}
		},
		indicator = {
			icon = '▎',
			style = 'underline'
		},
		offsets = {
			{
				filetype = "NvimTree",
				text = "File Explorer",
				highlight = "Directory",
				separator = true
			}
		},
	},
}

-- nvim-treesitter rewrite (branch `main`): the old
-- `require('nvim-treesitter.configs').setup()` module no longer exists.
-- New API: require('nvim-treesitter').setup() + .install(), highlighting via
-- vim.treesitter.start(). Keep a pcall fallback so the `master` branch still works.
do
	local ok, ts = pcall(require, 'nvim-treesitter')
	if ok and ts.setup then
		ts.setup({
			install_dir = vim.fn.stdpath('data') .. '/site',
		})
		-- Install the parsers we care about (no-op if already installed).
		local ok_inst, _ = pcall(function()
			ts.install({ 'c', 'cpp', 'lua', 'python', 'javascript', 'html', 'css', 'vim', 'vimdoc', 'query', 'markdown', 'markdown_inline' })
		end)
		if not ok_inst then
			vim.notify("nvim-treesitter: parser install failed, run :TSUpdate manually", vim.log.levels.WARN)
		end
		-- Enable treesitter highlighting + indent for every filetype that has one.
		vim.api.nvim_create_autocmd('FileType', {
			pattern = '*',
			callback = function(args)
				local lang = vim.treesitter.language.get_lang(args.match) or args.match
				-- Only start if a parser exists; otherwise fall back to syntax on.
				if pcall(vim.treesitter.language.add, lang) then
					pcall(vim.treesitter.start, args.buf, lang)
				end
			end,
		})
		-- Experimental treesitter indent where available.
		pcall(function()
			vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end)
	else
		-- Fallback for the legacy `master` branch API.
		local ok_legacy, ts_configs = pcall(require, 'nvim-treesitter.configs')
		if ok_legacy then
			ts_configs.setup({
			  ensure_installed = { "c", "cpp", "lua", "python", "javascript", "html", "css" },
			  auto_install = true,
			  highlight = { enable = true },
			  incremental_selection = {
				enable = true,
				keymaps = {
				  init_selection = "ss",
				  node_incremental = "si",
				  scope_incremental = "sc",
				  node_decremental = "sd",
				},
			  },
			})
		else
			vim.notify("nvim-treesitter not found", vim.log.levels.WARN)
		end
	end
end
-- Make sure Vim syntax highlighting is on as a fallback under treesitter.
vim.cmd("syntax on")

require("toggleterm").setup({
	direction = "horizontal",
	size = 30,
	float_opts = {
		border = "double",
	},
})
function _G.set_terminal_keymaps()
  local opts = { noremap = true }
  vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "jk", [[<C-\><C-n>]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "<C-h>", [[<C-\><C-n><C-W>h]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "<C-j>", [[<C-\><C-n><C-W>j]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "<C-k>", [[<C-\><C-n><C-W>k]], opts)
  vim.api.nvim_buf_set_keymap(0, "t", "<C-l>", [[<C-\><C-n><C-W>l]], opts)
end

vim.cmd "autocmd! TermOpen term://* lua set_terminal_keymaps()"

require("gitsigns").setup()

local db = require("dashboard")
db.setup({
  theme = 'doom',
  config = {
	header = {}, --your header
	center = {
	  {
		icon = ' ',
		icon_hl = 'Title',
		desc = 'Find File',
		desc_hl = 'String',
		key = 'b',
		keymap = 'SPC f f',
		key_hl = 'Number',
		action = 'lua print(2)'
	  },
	  {
		icon = ' ',
		desc = 'Find Dotfiles',
		key = 'f',
		keymap = 'SPC f d',
		action = 'lua print(3)'
	  },
	},
	footer = {}  --your footer
  }
})
