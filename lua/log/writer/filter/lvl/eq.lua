local Log = require "log"

local M = {}

function M.new(max_lvl, writer)
  assert((max_lvl == 0) or (Log.LVL_NAMES[max_lvl]))
  return function(msg, lvl, now)
    if lvl == max_lvl then writer(msg, lvl, now) end
  end
end

return M