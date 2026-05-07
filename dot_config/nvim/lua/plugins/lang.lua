return {
	{
		"lervag/vimtex",
		lazy = false,
		init = function()
			-- Use Skim as the PDF viewer on macOS
			vim.g.vimtex_view_method = "skim"

			-- Let VimTeX handle LaTeX syntax highlighting
			vim.g.vimtex_syntax_enabled = 1

			-- Use latexmk for continuous compilation
			vim.g.vimtex_compiler_method = "latexmk"
			vim.g.vimtex_compiler_latexmk = {
				continuous = 1,
				callback = 1,
				options = {
					"-pdf",
					"-interaction=nonstopmode",
					"-synctex=1",
					"-file-line-error",
				},
			}
		end,
		config = function()
			-- Compile continuously
			vim.keymap.set("n", "<leader>ll", "<cmd>VimtexCompile<CR>", {
				desc = "VimTeX compile",
			})

			-- Open/view PDF
			vim.keymap.set("n", "<leader>lv", "<cmd>VimtexView<CR>", {
				desc = "VimTeX view PDF",
			})

			-- Stop compilation
			vim.keymap.set("n", "<leader>lk", "<cmd>VimtexStop<CR>", {
				desc = "VimTeX stop compiler",
			})

			-- Clean auxiliary files
			vim.keymap.set("n", "<leader>lc", "<cmd>VimtexClean<CR>", {
				desc = "VimTeX clean",
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		branch = "main",
		config = function()
			local parsers = {
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
			}

			require("nvim-treesitter").install(parsers)

			local function treesitter_try_attach(buf, language)
				if not vim.treesitter.language.add(language) then
					return
				end

				vim.treesitter.start(buf, language)
				vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end

			local available_parsers = require("nvim-treesitter").get_available()

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local buf, filetype = args.buf, args.match

					-- Disable Treesitter for LaTeX files.
					-- This lets VimTeX handle syntax highlighting and math-zone detection.
					if vim.tbl_contains({ "tex", "plaintex", "latex" }, filetype) then
						return
					end

					local language = vim.treesitter.language.get_lang(filetype)
					if not language then
						return
					end

					local installed_parsers = require("nvim-treesitter").get_installed("parsers")

					if vim.tbl_contains(installed_parsers, language) then
						treesitter_try_attach(buf, language)
					elseif vim.tbl_contains(available_parsers, language) then
						require("nvim-treesitter").install(language):await(function()
							treesitter_try_attach(buf, language)
						end)
					else
						treesitter_try_attach(buf, language)
					end
				end,
			})
		end,
	},
}
