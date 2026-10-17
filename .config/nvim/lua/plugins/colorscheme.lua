return {
  {
    "rebelot/kanagawa.nvim",
    opts = {
      transparent = true,
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none"
            },
          },
        },
      },
      overrides = function()
        return {
          NormalFloat = { bg = "none" },
          FloatBorder = { bg = "none" },
          FloatTitle = { bg = "none" },
          StatusLine = { bg = "none" },
          StatusLineNC = { bg = "none" },
          TabLine = { bg = "none" },
          TabLineFill = { bg = "none" },
          TabLineSel = { bg = "none" },
          VertSplit = { bg = "none" },
          WinSeparator = { fg = "#625e5a", bg = "none" },
        }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-dragon",
    },
  },
}
