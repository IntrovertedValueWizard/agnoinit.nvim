-- ~/.config/nvim/lua/agnoinit/init.lua

local M = {}

-- Require the config and utils modules
local config_module = require("agnoinit.config")
local utils = require("agnoinit.utils")

-- Merged configuration, updated during M.setup
local config = {}

-- List to track created paths for rollback
local created_paths = {}

--- Helper for consistent notifications
--- @param msg string The message to display.
--- @param level vim.log.levels|nil The log level (e.g., vim.log.levels.INFO, ERROR).
local function notify_msg(msg, level)
  vim.notify("AgnoInit: " .. msg, level or vim.log.levels.INFO)
end

--- Cleans up the project directory if an error occurs during new project creation.
--- @param project_root_path string The root path of the project to clean up.
local function clean_up(project_root_path)
  notify_msg("Error detected. Attempting to clean up project at: " .. project_root_path, vim.log.levels.WARN)
  if vim.fn.isdirectory(project_root_path) == 1 then
    -- Remove the entire project directory
    vim.loop.fs_rmdir(project_root_path, { recursive = true }, function(err)
      if err then
        notify_msg("Failed to remove project directory '" .. project_root_path .. "': " .. err, vim.log.levels.ERROR)
      else
        notify_msg("Successfully removed project directory: " .. project_root_path, vim.log.levels.INFO)
      end
    end)
  else
    notify_msg("Project directory '" .. project_root_path .. "' not found for cleanup.", vim.log.levels.INFO)
  end
  created_paths = {} -- Clear tracking after cleanup attempt
end

--- Ensures the current working directory is a Flutter project root.
--- @param project_path string The path to the potential project root.
--- @return boolean True if it's a valid Flutter project root, false otherwise.
local function ensure_in_flutter_project_root(project_path)
  if not project_path or vim.fn.isdirectory(project_path) == 0 then
    notify_msg("Invalid project path: " .. (project_path or "nil"), vim.log.levels.ERROR)
    return false
  end

  local pubspec_path = utils.path_join(project_path, "pubspec.yaml")
  local lib_path = utils.path_join(project_path, "lib")

  if vim.fn.filereadable(pubspec_path) == 0 then
    notify_msg("Error: pubspec.yaml not found. Not a Flutter project root or invalid path.", vim.log.levels.ERROR)
    return false
  end
  if vim.fn.isdirectory(lib_path) == 0 then
    notify_msg("Error: 'lib' directory not found. Not a Flutter project root or invalid path.", vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Detects the framework based on files in the current directory. (Basic detection for now)
--- @return string The detected framework (e.g., "flutter") or configured default.
local function detect_framework()
  -- More robust detection could be implemented here if needed for non-flutter frameworks.
  -- For now, it simply checks for .dart files and defaults to 'flutter'.
  local files = vim.fn.globpath(vim.fn.getcwd(), "*.dart")
  if files ~= "" then
    return "flutter"
  end
  return config.framework -- Fallback to configured framework
end

--- Validates essential parts of the configuration.
--- @param cfg table The configuration table.
--- @return boolean True if configuration is valid, false otherwise.
local function validate_config(cfg)
  -- For now, we rely on ensure_in_flutter_project_root for existing projects
  -- and create_project handles new project path validation.
  if not cfg.framework then
    notify_msg("No framework defined in config.", vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Creates a list of folders relative to a base path.
--- Tracks created paths for potential rollback.
--- @param base_path string The absolute base path to create folders under.
--- @param folders_table table A list of folder paths (relative to base_path).
--- @param feature_name_capitalized string|nil Optional: Capitalized feature name for presentation folders.
--- @return boolean True on success, false on failure.
local function create_folders(base_path, folders_table, feature_name_capitalized)
  for _, folder_relative_path in ipairs(folders_table) do
    local folder_to_create = folder_relative_path
    -- Handle dynamic naming for feature presentation folders
    if feature_name_capitalized and folder_relative_path:match("^presentation/.+{{FEATURE_CAPITALIZED}}$") then
      folder_to_create = folder_relative_path:gsub("{{FEATURE_CAPITALIZED}}", feature_name_capitalized)
    end

    local full_path = utils.path_join(base_path, folder_to_create)
    local status, err = pcall(vim.fs.mkdir, full_path, true) -- `true` for recursive
    if not status then
      notify_msg("Failed to create directory '" .. full_path .. "': " .. err, vim.log.levels.ERROR)
      return false
    end
    table.insert(created_paths, full_path) -- Track for rollback
  end
  return true
end

--- Installs predefined dependencies for a given framework and project.
--- @param project_path string Absolute path to the project root.
--- @param framework string The framework to install dependencies for.
--- @param on_complete fun(success: boolean) Callback when installation finishes.
local function install_dependencies_workflow(project_path, framework, on_complete)
  local deps = config.dependencies[framework] or {}
  if #deps == 0 then
    notify_msg("No dependencies defined for " .. framework .. ". Skipping.", vim.log.levels.WARN)
    on_complete(true)
    return
  end

  local cmd = framework == "flutter" and "flutter" or nil
  if not cmd then
    notify_msg("Unsupported framework for dependency installation: " .. framework, vim.log.levels.ERROR)
    on_complete(false)
    return
  end

  local args = { "pub", "add" }
  vim.list_extend(args, deps) -- Add all dependencies as arguments

  notify_msg("Installing dependencies: " .. table.concat(deps, ", "), vim.log.levels.INFO)

  utils.run_async_cmd(
    cmd,
    args,
    function()
      notify_msg("All dependencies installed successfully.", vim.log.levels.INFO)
      on_complete(true)
    end,
    function(err)
      notify_msg("Failed to install dependencies: " .. err, vim.log.levels.ERROR)
      on_complete(false)
    end,
    project_path -- Run command in the project's root directory
  )
end

--- Creates the custom core folder structure in the project's lib directory.
--- @param project_path string Absolute path to the project root.
--- @return boolean True on success, false on failure.
local function create_core_structure_workflow(project_path)
  local lib_path = utils.path_join(project_path, "lib")
  if vim.fn.isdirectory(lib_path) == 0 then
    notify_msg("Error: 'lib' directory not found in project: " .. project_path, vim.log.levels.ERROR)
    return false
  end

  notify_msg("Creating core folder structure...", vim.log.levels.INFO)
  local success = create_folders(lib_path, config.core_folder_structure)
  if success then
    notify_msg("Core folder structure created successfully.", vim.log.levels.INFO)
  else
    notify_msg("Failed to create core folder structure.", vim.log.levels.ERROR)
  end
  return success
end

--- Creates feature-specific folder structures.
--- @param project_path string Absolute path to the project root.
--- @param feature_names_input string Comma-separated feature names.
--- @return boolean True on success, false on failure.
local function create_feature_structure_workflow(project_path, feature_names_input)
  if not feature_names_input or feature_names_input == "" then
    notify_msg("No feature names provided. Skipping feature creation.", vim.log.levels.WARN)
    return true
  end

  local lib_features_path = utils.path_join(project_path, "lib")
  -- Ensure the base features directory exists
  local status, err = vim.fs.stat(lib_features_path) ~= nil
  if not status then
    notify_msg("Failed to create base features directory '" .. lib_features_path .. "': " .. err, vim.log.levels.ERROR)
    return false
  end
  table.insert(created_paths, lib_features_path) -- Track for rollback

  local features = vim.split(feature_names_input, ",", { trimempty = true })
  local all_success = true

  for _, feature in ipairs(features) do
    local trimmed_feature = feature:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
    if trimmed_feature ~= "" then
      local feature_name_capitalized = utils.capitalize_first_letter(trimmed_feature)
      local feature_base_path = utils.path_join(lib_features_path, trimmed_feature)

      notify_msg("Creating structure for feature: " .. trimmed_feature, vim.log.levels.INFO)
      local success = create_folders(feature_base_path, config.feature_folder_template, feature_name_capitalized)
      if success then
        -- Also create the presentation subfolders using dynamic names
        local presentation_path = utils.path_join(feature_base_path, "presentation")
        local add_path = utils.path_join(presentation_path, "add" .. feature_name_capitalized)
        local edit_path = utils.path_join(presentation_path, "edit" .. feature_name_capitalized)
        local list_path = utils.path_join(presentation_path, "list" .. feature_name_capitalized)

        if not vim.fs.mkdir(add_path, true) or not vim.fs.mkdir(edit_path, true) or not vim.fs.mkdir(list_path, true) then
            notify_msg("Failed to create presentation subfolders for feature: " .. trimmed_feature, vim.log.levels.ERROR)
            success = false
        else
            table.insert(created_paths, add_path)
            table.insert(created_paths, edit_path)
            table.insert(created_paths, list_path)
        end
        
        if success then
            notify_msg("Feature '" .. trimmed_feature .. "' structure created successfully.", vim.log.levels.INFO)
        else
            all_success = false -- Mark overall failure
        end
      else
        all_success = false -- Mark overall failure
      end
    end
  end
  return all_success
end

--- Workflow for creating a new Flutter project from scratch.
--- @param project_name string The name of the new Flutter project.
local function handle_new_project(project_name)
  local project_root_path = utils.path_join(config.project_base_dir, project_name)
  local framework = detect_framework()

  if vim.fn.isdirectory(project_root_path) == 1 then
    notify_msg("Error: Directory '" .. project_name .. "' already exists. Aborting.", vim.log.levels.ERROR)
    return
  end

  notify_msg("Creating Flutter project '" .. project_name .. "'...", vim.log.levels.INFO)
  created_paths = {} -- Reset for new project rollback

  -- Step 1: flutter create
  utils.run_async_cmd(
    "flutter",
    {"create", project_name, "--org=com.example"}, -- --org is optional
    function()
      notify_msg("Project '" .. project_name .. "' created successfully.", vim.log.levels.INFO)
      table.insert(created_paths, project_root_path) -- Track the root for rollback

      -- Step 2: Install dependencies
      install_dependencies_workflow(project_root_path, framework, function(deps_success)
        if not deps_success then clean_up(project_root_path); return end

        -- Step 3: Create core folder structure
        if not create_core_structure_workflow(project_root_path) then clean_up(project_root_path); return end

        -- Step 4: Prompt for and create feature folders
        vim.ui.input({
          prompt = "Enter feature names (comma-separated, e.g., User, Product): ",
          default = "",
        }, function(feature_input)
          if feature_input then
            if not create_feature_structure_workflow(project_root_path, feature_input) then clean_up(project_root_path); return end
          end
          notify_msg("Full project setup for '" .. project_name .. "' complete!", vim.log.levels.INFO)
          created_paths = {} -- Clear tracking on success
        end)
      end)
    end,
    function(err)
      notify_msg("Failed to create project '" .. project_name .. "': " .. err, vim.log.levels.ERROR)
      clean_up(project_root_path)
    end,
    config.project_base_dir -- Run flutter create in the base directory
  )
end

--- Workflow for adding dependencies to an existing project.
--- @param project_path string Absolute path to the existing project root.
local function handle_add_dependencies(project_path)
  if not ensure_in_flutter_project_root(project_path) then return end
  local framework = detect_framework()

  install_dependencies_workflow(project_path, framework, function(success)
    if success then
      notify_msg("Dependencies added to '" .. project_path .. "'.", vim.log.levels.INFO)
    else
      notify_msg("Failed to add dependencies to '" .. project_path .. "'.", vim.log.levels.ERROR)
    end
  end)
end

--- Workflow for creating core folder structure in an existing project.
--- @param project_path string Absolute path to the existing project root.
local function handle_create_core_folders(project_path)
  if not ensure_in_flutter_project_root(project_path) then return end

  if create_core_structure_workflow(project_path) then
    notify_msg("Core folder structure added to '" .. project_path .. "'.", vim.log.levels.INFO)
  else
    notify_msg("Failed to add core folder structure to '" .. project_path .. "'.", vim.log.levels.ERROR)
  end
end

--- Workflow for creating feature folders in an existing project.
--- @param project_path string Absolute path to the existing project root.
local function handle_create_feature_folders() -- Removed project_path argument
  local current_working_dir = vim.fn.getcwd() -- Query the current directory here

  vim.ui.input({
    prompt = "Enter feature names (comma-separated, e.g., User, Product): ",
    default = "",
  }, function(feature_input)
    if feature_input then
      -- Pass the directly queried current_working_dir to the workflow function
      if create_feature_structure_workflow(current_working_dir, feature_input) then
        notify_msg("Feature folder(s) added to '" .. current_working_dir .. "'.", vim.log.levels.INFO)
      else
        notify_msg("Failed to add feature folder(s) to '" .. current_working_dir .. "'.", vim.log.levels.ERROR)
      end
    else
      notify_msg("No feature names provided. Aborting.", vim.log.levels.INFO)
    end
  end)
end
--- Main setup function for the plugin. Called by Lazy.nvim.
--- @param user_config table User-provided configuration to merge with defaults.
function M.setup(user_config)
  -- Merge user config with default_config from config_module
  config = vim.tbl_deep_extend("force", config_module.default_config, user_config or {})

  -- Register the main AgnoInit command
  vim.api.nvim_create_user_command("AgnoInit", function()
    local options = {
      "Set up a New Flutter Project (Create, Add Dependencies, Core, Features)",
      "Add Predefined Dependencies to an existing project",
      "Create Core Folder structure in an existing project",
      "Create Feature Folders in an existing project",
      "Exit",
    }

    vim.ui.select(options, {
      prompt = "Select an AgnoInit action:",
      kind = "AgnoInitMenu", -- Optional: for custom highlights or sorting
    }, function(choice)
      if not choice then
        notify_msg("Menu selection cancelled.", vim.log.levels.INFO)
        return
      end

      local current_project_path = vim.fn.getcwd()

      if choice == options[1] then
        -- New Project
        vim.ui.input({ prompt = "Enter the new Flutter project name: " }, function(project_name)
          if project_name and project_name ~= "" then
            handle_new_project(project_name)
          else
            notify_msg("No project name entered. Aborting.", vim.log.levels.WARN)
          end
        end)
      elseif choice == options[2] then
        -- Add Dependencies
        handle_add_dependencies(current_project_path)
      elseif choice == options[3] then
        -- Create Core Folder Structure
        handle_create_core_folders(current_project_path)
      elseif choice == options[4] then
        -- Create Feature Folders
        handle_create_feature_folders()
      elseif choice == options[5] then
        -- Exit
        notify_msg("Exiting AgnoInit. Goodbye!", vim.log.levels.INFO)
      end
    end)
  end, { nargs = 0, desc = "AgnoInit: Orchestrates project setup tasks" })

  notify_msg("AgnoInit plugin loaded. Use :AgnoInit to begin.", vim.log.levels.INFO)
end

return M
