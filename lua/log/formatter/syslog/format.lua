local base = require "log.formatter.syslog"

local M = {}

function M.new(...)
  local writer = base.new(...)
  local fmt = string.format

  return function (now, lvl, ...)
    return writer(now, lvl, (fmt(...)))
  end
end

return M
