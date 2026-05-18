return {
  'lervag/vimtex',
  lazy = false,
  init = function()
    -- Use Skim as the PDF viewer on macOS
    vim.g.vimtex_view_method = 'skim'

    -- Let VimTeX handle LaTeX syntax highlighting
    vim.g.vimtex_syntax_enabled = 1

    -- Use latexmk for continuous compilation
    vim.g.vimtex_compiler_method = 'latexmk'
    vim.g.vimtex_compiler_latexmk = {
      continuous = 1,
      callback = 1,
      options = {
        '-pdf',
        '-interaction=nonstopmode',
        '-synctex=1',
        '-file-line-error',
      },
    }
  end,
  config = function()
    -- Compile continuously
    vim.keymap.set('n', '<leader>ll', '<cmd>VimtexCompile<CR>', {
      desc = 'VimTeX compile',
    })

    -- Open/view PDF
    vim.keymap.set('n', '<leader>lv', '<cmd>VimtexView<CR>', {
      desc = 'VimTeX view PDF',
    })

    -- Stop compilation
    vim.keymap.set('n', '<leader>lk', '<cmd>VimtexStop<CR>', {
      desc = 'VimTeX stop compiler',
    })

    -- Clean auxiliary files
    vim.keymap.set('n', '<leader>lc', '<cmd>VimtexClean<CR>', {
      desc = 'VimTeX clean',
    })
  end,
}
