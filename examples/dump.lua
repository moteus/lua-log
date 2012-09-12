local LOG = require"log".new('DEBUG',
  require "log.writer.console.color".new()
)

local pretty = require "pl.pretty"
local dump = function(msg, var) return msg .. '\n' .. pretty.write(var) end

local context = {
  private_ = {
    srv = '127.0.0.1';
  }
}

LOG.debug_dump(dump,"try connect to server ...",context)


print("Press enter ...")io.flush()
io.read()