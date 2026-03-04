# EDITORS.md - Editor Configuration Guide

This document provides editor setup and workflow guidance for the preferred editors in this project.

## Editor Preferences

**Primary (Preferred)**: LazyVim (Neovim distribution)
**Secondary (Acceptable)**: VSCode

All AI assistants should assume LazyVim unless explicitly told otherwise. However, VSCode guidance should be available for team members who prefer it.

---

## LazyVim (Preferred)

### Overview

LazyVim is a Neovim configuration distribution that provides:

- Pre-configured best practices out of the box
- Which-key for command discoverability
- Consistent keybindings across languages
- Superior performance and terminal integration
- Active development and community

### Installation

```bash
# Backup existing Neovim config
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak

# Install LazyVim
git clone https://github.com/LazyVim/starter ~/.config/nvim
nvim
```

### Configuration Structure

```
~/.config/nvim/
├── lua/
│   ├── config/
│   │   ├── autocmds.lua    # Auto commands
│   │   ├── keymaps.lua     # Custom keymaps
│   │   ├── lazy.lua        # Lazy.nvim setup + extras
│   │   └── options.lua     # Vim options
│   └── plugins/
│       ├── go.lua          # Go-specific plugins
│       ├── python.lua      # Python-specific plugins
│       ├── typescript.lua  # TypeScript-specific plugins
│       └── powershell.lua  # PowerShell-specific plugins
└── init.lua                # Entry point
```

### Universal LazyVim Keybindings

```vim
Leader key: <space>

" Help & Discovery
<leader>?         " Which-key help (shows all available keys)

" Files
<leader>ff        " Find files (Telescope)
<leader>fr        " Recent files
<leader>fb        " Find buffers
<leader>fn        " New file
<leader>fe        " Toggle file explorer (Neo-tree)

" Search
<leader>sg        " Live grep (search in files)
<leader>sw        " Search word under cursor
<leader>ss        " Search symbols (LSP)

" LSP (universal across languages)
gd                " Go to definition
gD                " Go to declaration
gr                " Go to references
gI                " Go to implementation
K                 " Hover documentation
<leader>ca        " Code actions
<leader>cr        " Rename symbol
<leader>cf        " Format buffer
<leader>cd        " Line diagnostics
[d                " Previous diagnostic
]d                " Next diagnostic

" Debugging (<leader>d namespace)
<leader>db        " Toggle breakpoint
<leader>dB        " Conditional breakpoint
<leader>dc        " Continue
<leader>ds        " Step over
<leader>di        " Step into
<leader>do        " Step out
<leader>du        " Toggle DAP UI

" Testing (<leader>t namespace)
<leader>tt        " Run nearest test
<leader>tT        " Run all tests in file
<leader>tf        " Run test file
<leader>ts        " Test summary
<leader>to        " Test output

" Terminal
<C-/>             " Toggle terminal
<leader>ft        " Terminal (new)

" Windows
<C-h>             " Move to left window
<C-j>             " Move to window below
<C-k>             " Move to window above
<C-l>             " Move to right window

" Plugins
<leader>l         " Lazy (plugin manager)
```

### LazyVim Plugin Configuration Pattern

Always **extend**, never replace LazyVim's defaults:

```lua
-- ~/.config/nvim/lua/plugins/example.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          -- Your settings here
          -- LazyVim's defaults are preserved
        },
      },
    },
  },
}
```

### LazyVim Extras System

Enable language-specific features via extras:

```lua
-- ~/.config/nvim/lua/config/lazy.lua
return {
  -- Language extras
  { import = "lazyvim.plugins.extras.lang.go" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- Feature extras
  { import = "lazyvim.plugins.extras.dap.core" },        -- Debugging
  { import = "lazyvim.plugins.extras.test.core" },       -- Testing
  { import = "lazyvim.plugins.extras.formatting.prettier" },
  { import = "lazyvim.plugins.extras.linting.eslint" },
}
```

---

## Language-Specific LazyVim Setup

### Go

```lua
-- ~/.config/nvim/lua/plugins/go.lua
return {
  -- Enable LazyVim's Go extra first
  { import = "lazyvim.plugins.extras.lang.go" },

  -- Extend gopls configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {
          settings = {
            gopls = {
              gofumpt = true,
              codelenses = {
                generate = true,
                test = true,
                tidy = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                parameterNames = true,
              },
              analyses = {
                fieldalignment = true,
                nilness = true,
                unusedparams = true,
              },
              staticcheck = true,
            },
          },
        },
      },
    },
  },

  -- Add go.nvim for additional tooling
  {
    "ray-x/go.nvim",
    dependencies = { "ray-x/guihua.lua" },
    opts = {
      lsp_cfg = false, -- LazyVim handles LSP
      dap_debug = true,
    },
    config = function(_, opts)
      require("go").setup(opts)

      -- Auto format on save
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
          require("go.format").goimport()
        end,
      })
    end,
    ft = { "go", "gomod" },
  },

  -- Extend DAP for Go
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      { "leoluz/nvim-dap-go", config = true },
    },
  },

  -- Extend Neotest for Go
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "nvim-neotest/neotest-go" },
    opts = {
      adapters = {
        ["neotest-go"] = {
          experimental = { test_table = true },
          args = { "-count=1", "-timeout=60s" },
        },
      },
    },
  },
}
```

**Go-specific keymaps**:

```lua
-- ~/.config/nvim/lua/config/keymaps.lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function(event)
    local opts = { buffer = event.buf }

    -- Use <leader>c namespace for code actions
    vim.keymap.set("n", "<leader>cR", "<cmd>GoRun<cr>", opts)
    vim.keymap.set("n", "<leader>cb", "<cmd>GoBuild<cr>", opts)
    vim.keymap.set("n", "<leader>cI", "<cmd>GoIfErr<cr>", opts)
    vim.keymap.set("n", "<leader>cF", "<cmd>GoFillStruct<cr>", opts)
    vim.keymap.set("n", "<leader>ct", "<cmd>GoTest<cr>", opts)
    vim.keymap.set("n", "<leader>cT", "<cmd>GoTestFunc<cr>", opts)

    -- Debug test under cursor
    vim.keymap.set("n", "<leader>dT", function()
      require("dap-go").debug_test()
    end, opts)
  end,
})
```

### Python

```lua
-- ~/.config/nvim/lua/plugins/python.lua
return {
  -- Enable LazyVim's Python extra first
  { import = "lazyvim.plugins.extras.lang.python" },

  -- Extend LSP configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "strict",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        ruff_lsp = {
          on_attach = function(client, bufnr)
            client.server_capabilities.hoverProvider = false
          end,
        },
      },
    },
  },

  -- Extend DAP for Python
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      { "mfussenegger/nvim-dap-python", config = function()
        require("dap-python").setup("~/.virtualenvs/debugpy/bin/python")
      end },
    },
  },

  -- Extend Neotest for Python
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "nvim-neotest/neotest-python" },
    opts = {
      adapters = {
        ["neotest-python"] = {
          dap = { justMyCode = false },
          args = { "--log-level", "DEBUG", "-vv" },
          runner = "pytest",
        },
      },
    },
  },
}
```

**Python-specific keymaps**:

```lua
-- ~/.config/nvim/lua/config/keymaps.lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function(event)
    local opts = { buffer = event.buf }

    -- Run with uv
    vim.keymap.set("n", "<leader>cR", "<cmd>!uv run python %<cr>", opts)
    vim.keymap.set("n", "<leader>cp", "<cmd>!uv run pytest<cr>", opts)

    -- Debug test
    vim.keymap.set("n", "<leader>dT", function()
      require("dap-python").test_method()
    end, opts)
  end,
})
```

### TypeScript/Vue/Nuxt

```lua
-- ~/.config/nvim/lua/plugins/typescript.lua
return {
  -- Enable LazyVim's TypeScript extra first
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- Add Vue/Nuxt support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        volar = {
          filetypes = { "vue", "typescript", "javascript" },
        },
        tsserver = {
          init_options = {
            plugins = {
              {
                name = "@vue/typescript-plugin",
                location = "",  -- Will be auto-detected by Mason
                languages = { "vue" },
              },
            },
          },
          filetypes = { "typescript", "javascript", "vue" },
        },
      },
    },
  },

  -- Extend Neotest for Vitest
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "marilari88/neotest-vitest" },
    opts = {
      adapters = {
        ["neotest-vitest"] = {},
      },
    },
  },
}
```

**TypeScript/Vue-specific keymaps**:

```lua
-- ~/.config/nvim/lua/config/keymaps.lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "vue", "typescript", "javascript" },
  callback = function(event)
    local opts = { buffer = event.buf }

    vim.keymap.set("n", "<leader>cd", "<cmd>!npm run dev<cr>", opts)
    vim.keymap.set("n", "<leader>cb", "<cmd>!npm run build<cr>", opts)
    vim.keymap.set("n", "<leader>ct", "<cmd>!vue-tsc --noEmit<cr>", opts)
  end,
})
```

### PowerShell

```lua
-- ~/.config/nvim/lua/plugins/powershell.lua
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "powershell" })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        powershell_es = {
          bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
          settings = {
            powershell = {
              codeFormatting = {
                preset = "OTBS",
              },
              scriptAnalysis = {
                enable = true,
              },
            },
          },
        },
      },
    },
  },
}
```

**PowerShell-specific keymaps**:

```lua
-- ~/.config/nvim/lua/config/keymaps.lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "ps1",
  callback = function(event)
    local opts = { buffer = event.buf }

    vim.keymap.set("n", "<leader>cR", "<cmd>!pwsh -File %<cr>", opts)
    vim.keymap.set("n", "<leader>ct", "<cmd>!pwsh -Command 'Invoke-Pester %'<cr>", opts)
    vim.keymap.set("n", "<leader>cl", "<cmd>!pwsh -Command 'Invoke-ScriptAnalyzer %'<cr>", opts)
  end,
})
```

---

## VSCode (Acceptable Alternative)

### Overview

VSCode is acceptable for team members who prefer a GUI editor. It provides good language support and debugging capabilities.

### Recommended Extensions

#### Universal Extensions

- **Error Lens** - Inline error display
- **GitLens** - Git integration
- **Remote - SSH** - Remote development
- **Remote - Containers** - Container development
- **Prettier** - Code formatting
- **ESLint** - JavaScript/TypeScript linting

#### Go Extensions

- **Go** (golang.go) - Official Go extension
- **Go Test Explorer** - Test UI

#### Python Extensions

- **Python** (ms-python.python) - Official Python extension
- **Pylance** - Type checking and IntelliSense
- **Ruff** - Fast linting and formatting
- **Python Debugger** - Debugging support

#### TypeScript/Vue Extensions

- **Volar** (Vue.volar) - Vue language support
- **TypeScript Vue Plugin** (Vue.vscode-typescript-vue-plugin)
- **ESLint** - Linting
- **Prettier** - Formatting

#### PowerShell Extensions

- **PowerShell** (ms-vscode.powershell) - Official PowerShell extension

### VSCode Settings

```json
// settings.json
{
  // Editor
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  },
  "editor.rulers": [100],
  "editor.minimap.enabled": false,

  // Files
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,

  // Go
  "[go]": {
    "editor.defaultFormatter": "golang.go",
    "editor.formatOnSave": true
  },
  "go.useLanguageServer": true,
  "gopls": {
    "ui.semanticTokens": true,
    "ui.codelenses": {
      "generate": true,
      "test": true,
      "tidy": true
    }
  },

  // Python
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnSave": true
  },
  "python.analysis.typeCheckingMode": "strict",

  // TypeScript/Vue
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[vue]": {
    "editor.defaultFormatter": "Vue.volar"
  },

  // PowerShell
  "[powershell]": {
    "editor.defaultFormatter": "ms-vscode.powershell"
  }
}
```

### VSCode Keybindings

```json
// keybindings.json (optional customization)
[
  {
    "key": "ctrl+p",
    "command": "workbench.action.quickOpen"
  },
  {
    "key": "ctrl+shift+p",
    "command": "workbench.action.showCommands"
  },
  {
    "key": "ctrl+`",
    "command": "workbench.action.terminal.toggleTerminal"
  }
]
```

### VSCode Launch Configurations

#### Go Debugging

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Package",
      "type": "go",
      "request": "launch",
      "mode": "auto",
      "program": "${fileDirname}"
    },
    {
      "name": "Debug Test",
      "type": "go",
      "request": "launch",
      "mode": "test",
      "program": "${workspaceFolder}"
    }
  ]
}
```

#### Python Debugging

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Current File",
      "type": "python",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal"
    },
    {
      "name": "Python: Debug Tests",
      "type": "python",
      "request": "launch",
      "module": "pytest",
      "args": ["-v"],
      "console": "integratedTerminal"
    }
  ]
}
```

#### TypeScript/Vue Debugging

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Chrome",
      "type": "chrome",
      "request": "launch",
      "url": "http://localhost:3000",
      "webRoot": "${workspaceFolder}"
    }
  ]
}
```

---

## Editor Comparison

### LazyVim Advantages

- **Performance**: Faster startup and operation
- **Terminal Integration**: Native terminal workflows
- **Customization**: Lua-based configuration
- **Keyboard-Driven**: Minimal mouse usage
- **Consistency**: Same keybindings across languages
- **Which-key**: Command discoverability
- **Community**: Active Neovim ecosystem

### VSCode Advantages

- **GUI**: Visual interface for beginners
- **Extensions**: Large marketplace
- **Integrated Debugging**: Visual debugging UI
- **Git Integration**: Built-in GitLens
- **Remote Development**: Excellent remote support
- **Learning Curve**: Easier for new developers

---

## AI Assistant Guidelines

### When providing editor guidance:

1. **Default to LazyVim**:
   - Assume LazyVim unless told otherwise
   - Use LazyVim keybindings in examples
   - Reference which-key for discoverability

2. **LazyVim Configuration**:
   - Show `opts`-based plugin extensions
   - Place configs in `lua/plugins/*.lua`
   - Use appropriate keybinding namespaces
   - Reference LazyVim extras when available

3. **For VSCode Users**:
   - Provide VSCode-specific guidance when requested
   - Show settings.json and launch.json configs
   - Reference appropriate extensions

4. **Cross-Editor Concepts**:
   - Explain concepts editor-agnostically when possible
   - Show terminal commands that work in both
   - Focus on language tools, not editor specifics

5. **Debugging Advice**:
   - LazyVim: Reference nvim-dap and `<leader>d` keybindings
   - VSCode: Reference launch.json and debug pane

6. **Terminal Integration**:
   - LazyVim: `<C-/>` for terminal
   - VSCode: `` Ctrl+` `` for terminal
   - Both: Show raw terminal commands when appropriate

---

## Quick Reference

### LazyVim Quick Commands

```vim
<space>?          " Show all keybindings
<space>ff         " Find files
<space>sg         " Search in files
<space>ca         " Code actions
<space>tt         " Run test
<space>db         " Debug breakpoint
:Lazy             " Plugin manager
:Mason            " Tool installer
:LspInfo          " LSP status
```

### VSCode Quick Commands

```
Ctrl+P            " Quick Open files
Ctrl+Shift+P      " Command Palette
Ctrl+`            " Toggle Terminal
F5                " Start Debugging
Ctrl+Shift+D      " Debug sidebar
```

---

## Installation Scripts

### LazyVim Setup Script

```bash
#!/bin/bash
# install-lazyvim.sh

echo "Installing LazyVim..."

# Backup existing config
if [ -d ~/.config/nvim ]; then
    echo "Backing up existing Neovim config..."
    mv ~/.config/nvim ~/.config/nvim.bak.$(date +%Y%m%d-%H%M%S)
fi

# Install LazyVim starter
git clone https://github.com/LazyVim/starter ~/.config/nvim

# Remove .git directory
rm -rf ~/.config/nvim/.git

echo "LazyVim installed! Run 'nvim' to complete setup."
```

### VSCode Extensions Install Script

```bash
#!/bin/bash
# install-vscode-extensions.sh

echo "Installing VSCode extensions..."

# Universal
code --install-extension usernamehidden.errorlens
code --install-extension eamodio.gitlens

# Go
code --install-extension golang.go

# Python
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension charliermarsh.ruff

# TypeScript/Vue
code --install-extension Vue.volar
code --install-extension Vue.vscode-typescript-vue-plugin

# PowerShell
code --install-extension ms-vscode.powershell

echo "VSCode extensions installed!"
```

---

## Troubleshooting

### LazyVim

```vim
" Check health
:checkhealth lazy
:checkhealth lsp

" Update plugins
:Lazy update

" Clean unused plugins
:Lazy clean

" Check LSP
:LspInfo
:LspRestart
```

### VSCode

```
Developer: Reload Window (Ctrl+Shift+P)
Developer: Toggle Developer Tools
Output panel for errors
```
