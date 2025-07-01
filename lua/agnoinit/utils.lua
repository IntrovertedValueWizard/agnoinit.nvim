-- ~/.config/nvim/lua/agnoinit/utils.lua

local M = {}
local Job = require("plenary.job") -- Already present in your init.txt, moved here for modularity

--- Capitalizes the first letter of a string.
--- @param str string
--- @return string
function M.capitalize_first_letter(str)
  if not str or #str == 0 then
    return ""
  end
  return str:sub(1, 1):upper() .. str:sub(2)
end

--- Joins path segments, ensuring correct separators.
--- @param ... string Path segments to join.
--- @return string
function M.path_join(...)
  local path_segments = { ... }
  -- Remove any nils or empty strings from segments
  local cleaned_segments = {}
  for _, segment in ipairs(path_segments) do
    if segment and segment ~= "" then
      table.insert(cleaned_segments, segment)
    end
  end

  if #cleaned_segments == 0 then
    return ""
  end

  -- Use vim.fs.join_paths if available (Neovim 0.7+) for better cross-platform compatibility
  if vim.fs and vim.fs.join_paths then
    return vim.fs.join_paths(unpack(cleaned_segments))
  else
    -- Fallback for older Neovim versions or if vim.fs is not fully available
    -- This basic join assumes Unix-like paths and doesn't handle Windows paths perfectly
    return table.concat(cleaned_segments, "/")
  end
end

--- Runs an external command asynchronously using plenary.job.
--- @param cmd string The command to execute.
--- @param args table List of arguments for the command.
--- @param on_success fun(result: table) Callback function on success, receives stdout result.
--- @param on_error fun(err: table) Callback function on error, receives stderr result.
--- @param cwd string|nil Optional working directory for the command.
function M.run_async_cmd(cmd, args, on_success, on_error, cwd)
  local job_opts = {
    command = cmd,
    args = args,
    on_exit = function(j, return_val)
      if return_val == 0 then
        vim.schedule(function()
          on_success(j:result())
        end)
      else
        vim.schedule(function()
          -- Ensure err is a string for vim.notify
          local err_msg = table.concat(j:stderr_result(), "\n")
          on_error(err_msg)
        end)
      end
    end,
  }

  if cwd then
    job_opts.cwd = cwd
  end

  Job:new(job_opts):start()
end

return M
