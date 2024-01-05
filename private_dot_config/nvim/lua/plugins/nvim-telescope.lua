return {
  "nvim-telescope/telescope.nvim",
  keys = {
    { "<leader>tf", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<leader>tr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
    { "<leader>tb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    { "<leader>td", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
    { "<leader>tq", "<cmd>Telescope quickfix<cr>", desc = "Quickfix" },
  },
}
