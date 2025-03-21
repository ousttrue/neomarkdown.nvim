---@class neomarkdown.Logger
---@field logger table
local Logger = {}
Logger.__index = Logger
Logger.name = "lls_logger"

--- Retrieves the path of the logfile
---@return string path path of the logfile
function Logger.get_log_path()
  return vim.fs.joinpath(vim.fn.stdpath "cache" --[[@as string]], Logger.name .. ".log")
end

---@return neomarkdown.Logger
function Logger.new()
  local self = setmetatable({
    logger = require("plenary.log").new {
      plugin = Logger.name,
      level = "trace",
      -- use_console = false,
      use_console = "async",
      info_level = 4,
      use_file = true,
      outfile = Logger.get_log_path(),
    },
  }, Logger)
  self:trace("starting " .. Logger.name)
  return self
end

--- Adds a log entry using Plenary.log
---@param msg any
---@param level string [same as vim.log.log_levels]
function Logger:add_entry(msg, level)
  local fmt_msg = self.logger[level]
  ---@cast fmt_msg fun(msg: string)
  fmt_msg(msg)
end

---Add a log entry at TRACE level
---@param msg any
function Logger:trace(msg)
  self:add_entry(msg, "trace")
end

---Add a log entry at DEBUG level
---@param msg any
function Logger:debug(msg)
  self:add_entry(msg, "debug")
end

---Add a log entry at INFO level
---@param msg any
function Logger:info(msg)
  self:add_entry(msg, "info")
end

---Add a log entry at WARN level
---@param msg any
function Logger:warn(msg)
  self:add_entry(msg, "warn")
  vim.schedule(function()
    vim.notify(msg, vim.log.levels.WARN)
  end)
end

---Add a log entry at ERROR level
---@param msg any
function Logger:error(msg)
  self:add_entry(msg, "error")
  vim.schedule(function()
    vim.notify(msg, vim.log.levels.ERROR)
  end)
end

return Logger
