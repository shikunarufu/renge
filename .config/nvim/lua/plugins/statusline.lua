return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local c = require("kanagawa.colors").setup().palette

      local function mode(color)
        return {
          a = { fg = color, bg = "NONE", gui = "bold" },
          b = { fg = color, bg = "NONE" },
          c = { fg = c.fujiWhite, bg = "NONE" },
        }
      end

      opts.options = opts.options or {}
      opts.options.theme = {
        normal = mode(c.crystalBlue),
        insert = mode(c.springGreen),
        visual = mode(c.oniViolet),
        replace = mode(c.autumnRed),
        command = mode(c.boatYellow2),
        inactive = mode(c.fujiGray),
      }
      opts.options.section_separators = ""
      opts.options.component_separators = ""
    end,
  },
}
