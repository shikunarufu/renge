return {
  "akinsho/bufferline.nvim",
  opts = function(_, opts)
    local function clear()
      for name, hl in pairs(vim.api.nvim_get_hl(0, { link = false })) do
        if name:find("^BufferLine") then
          hl.bg = nil
          hl.ctermbg = nil
          vim.api.nvim_set_hl(0, name, hl)
        end
      end
    end
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.schedule(clear)
      end,
    })
    vim.schedule(clear)
    return opts
  end,
}
