-- ~/.config/nvim/lua/agnoinit/config.lua

local M = {}

M.default_config = {
  -- Default framework for project creation
  framework = "flutter",
  -- Default project directory (where the new project folder will be created)
  project_base_dir = vim.fn.getcwd(),

  -- Comprehensive list of Flutter dependencies
  -- This aligns with the list from our previous discussions
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
    },
    -- Add more frameworks and their dependencies here if needed in the future
    -- e.g., nodejs = { "express", "lodash" },
  },

  -- Custom core folder structure (relative to 'lib/' of the Flutter project)
  -- This translates your create_project_structure.sh logic
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
    "commonUiElements/addEditBase", -- Assuming this was fixed to be under commonUiElements
  },

  -- Custom feature folder structure (relative to the feature's base directory, e.g., 'lib/features/User/')
  -- This translates your create_feature_structure.sh logic
  feature_folder_template = {
    "data",
    "data/model",
    "data/repository",
    "domain",
    "domain/model",
    "domain/repository",
    "presentation",
    -- Presentation folders will be dynamically named based on capitalized feature name
    -- e.g., "presentation/add{{FEATURE_CAPITALIZED}}"
  },
  
  -- Template for initial files (optional, can be expanded)
  -- For now, we won't generate any complex file content but this is where it would go.
  initial_files = {
    -- { path = "lib/main.dart", content_template = "void main() => runApp(MyApp());" },
    -- { path = "README.md", content_template = "# {{project_name}}" },
  },
}

return M
