# AgnoInit.nvim

A Neovim plugin designed to streamline Flutter project setup, dependency management, and opinionated folder structure creation directly from your editor. AgnoInit helps you quickly scaffold new projects and maintain consistency across your existing Flutter codebase.

## ✨ Features

- **New Flutter Project Creation**: Interactively create a new Flutter project, including:
  - Execution of `flutter create`.
  - Automatic installation of a predefined set of common Flutter dependencies.
  - Creation of a customizable `core` folder structure within `lib/`.
  - Interactive creation of feature-specific folder structures (e.g., `lib/features/User/`, `lib/features/Product/`) with common subdirectories like `data`, `domain`, and `presentation`.

- **Add Dependencies to Existing Projects**: Easily add a predefined list of dependencies to any existing Flutter project's `pubspec.yaml`.

- **Create Core Folder Structure**: Apply your defined core folder structure to an existing Flutter project's `lib/` directory.

- **Create Feature Folders**: Generate feature-specific folder structures within `lib/features/` for existing projects, promoting modularity.

- **Configurable**: Customize default dependencies, core structure, and feature templates via a simple Lua configuration.

- **Rollback Mechanism**: Includes a basic cleanup mechanism for new project creation failures.

## 🚀 Installation

Install with your favorite package manager.

### Lazy.nvim

```lua
{
  'introvertedvaluewizard/agnoinit.nvim',
  name = 'agnoinit',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('agnoinit').setup({
      -- Optional: Customize your configuration here
      -- project_base_dir = vim.fn.expand('~/Projects/Flutter'),
      -- dependencies = {
      --   flutter = {
      --     "another_dependency",
      --     "some_other_package",
      --   },
      -- },
      -- core_folder_structure = {
      --   "new_core_folder",
      --   "new_core_folder/sub",
      -- },
      -- feature_folder_template = {
      --   "my_custom_feature_folder",
      -- },
    })
  end,
}
```

### Packer.nvim

```lua
use {
  'introvertedvaluewizard/agnoinit.nvim',
  requires = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('agnoinit').setup({
      -- Optional: Customize your configuration here
      -- project_base_dir = vim.fn.expand('~/Projects/Flutter'),
    })
  end,
}
```

### Vim-Plug

```vim
Plug 'introvertedvaluewizard/agnoinit.nvim' 
Plug 'nvim-lua/plenary.nvim'           

" Lua configuration (put this in your init.lua or a separate file sourced from init.vim)
lua << EOF
require('agnoinit').setup({
  -- Optional: Customize your configuration here
  -- project_base_dir = vim.fn.expand('~/Projects/Flutter'),
})
EOF
```

## ⚙️ Configuration

AgnoInit comes with sensible defaults, but you can customize its behavior by passing a table to the `setup()` function.

```lua
-- ~/.config/nvim/lua/your-config/agnoinit.lua
require('agnoinit').setup({
  -- Base directory where new projects will be created.
  -- Defaults to vim.fn.getcwd() (your current working directory).
  project_base_dir = vim.fn.expand('~/Code/FlutterProjects'),

  -- Define dependencies to be added for each framework.
  -- Currently primarily configured for 'flutter'.
  dependencies = {
    flutter = {
      "go_router",
      "bloc",
      "flutter_bloc",
      "uuid",
      "material_symbols_icons",
      "sqflite_common_ffi",
      "sqlite3_flutter_libs",
      "path_provider",
      "path",
      "get_it",
      "google_fonts",
      "intl",
      "equatable",
      "dartz",
      "flutter_launcher_icons",
      "collection",
      "shared_preferences",
      "smooth_page_indicator",
      "rxdart",
      -- Add or remove dependencies as needed
    },
    -- You can extend this for other frameworks if your plugin supports them in the future
    -- nodejs = { "express", "lodash" },
  },

  -- Define the core folder structure relative to the 'lib/' directory of your Flutter project.
  core_folder_structure = {
    "core",
    "core/dependencies",
    "core/dataSource",
    "core/dataSource/local",
    "core/dataSource/local/sqlite",
    "core/dataSource/local/sqlite/setup",
    "core/dataSource/local/sqlite/daos",
    "core/navigation",
    "core/themes",
    "core/utils",
    "commonUiElements",
    "commonUiElements/addEditBase",
  },

  -- Define the template for feature-specific folders.
  -- These are created relative to 'lib/features/YOUR_FEATURE_NAME/'.
  -- `presentation/add{{FEATURE_CAPITALIZED}}`, `presentation/edit{{FEATURE_CAPITALIZED}}`,
  -- and `presentation/list{{FEATURE_CAPITALIZED}}` are dynamically generated.
  feature_folder_template = {
    "data",
    "data/model",
    "data/repository",
    "domain",
    "domain/model",
    "domain/repository",
    "presentation",
  },
})
```

## 🚀 Usage

Once installed, run the main command:

```
:AgnoInit
```

This opens an interactive `vim.ui.select` menu with the following options:

- **Set up a New Flutter Project**: Guides you through creating a new project, installing dependencies, and setting up core and feature folders.
- **Add Predefined Dependencies to an existing project**: Installs the dependencies defined in your config to the current Flutter project.
- **Create Core Folder structure in an existing project**: Applies the core folder structure to the `lib/` directory of your current project.
- **Create Feature Folders in an existing project**: Prompts for feature names and creates the corresponding modular folder structures within `lib/features/`.
- **Exit**: Closes the AgnoInit menu.

## 🤝 Contributing

Contributions are welcome! If you have suggestions for new features, improvements, or bug fixes, please open an issue or submit a pull request on the [GitHub repository](https://github.com/introvertedvaluewizard/agnoinit.nvim).

## 📄 License

This plugin is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
