local base = require "log.formatter.syslog"

local M = {}

function M.new(sep, ...)
  local writer = base.new(...)
  sep = sep or ' '

  return function (now, lvl, ...)
    local argc,argv = select('#', ...), {...}
    for i = 1, argc do argv[i] = tostring(argv[i]) end
    return writer(now, lvl, table.concat(argv, sep))
  end
end

return M
