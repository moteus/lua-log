local LOG = require"log".new('DEBUG',
  require "log.writer.console.color".new(),
  require "log.formatter.mix".new()
)

local pretty = require "pl.pretty"
local dump = function(msg, var) return msg .. '\n' .. pretty.write(var) end

local context = {
  private_ = {
    srv = '127.0.0.1';
  }
}

-- this works for all formatters
LOG.debug_dump(dump,"try connect to server ...",context)

-- this works only for mix formatter
LOG.debug(dump, "try connect to server ...", context)
LOG.debug('%s, %s', 'hello', 'world')

print("Press enter ...")io.flush()
io.read()