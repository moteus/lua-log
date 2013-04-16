Asynchronous logging library for Lua 5.1/5.2

***

##Dependences##
###core###
* LuaDate

###writer.async.udp###
* [llthreads](http://github.com/Neopallium/lua-llthreads)
* writer.net.udp

###writer.async.zmq###
* [llthreads](http://github.com/Neopallium/lua-llthreads)
* writer.net.zmq

###writer.async.lane###
* [LuaLanes](https://github.com/LuaLanes/lanes) - This is experemental writer

###writer.console.color###
* ansicolors
* or lua-conio
* or cio (Windows only)

###writer.file.by_day###
* [lfs](http://keplerproject.github.com/luafilesystem)

###writer.net.udp###
* [LuaSocket](http://www.impa.br/~diego/software/luasocket)

###writer.net.zmq###
* [lua-zmq](http://github.com/Neopallium/lua-zmq)
* or [lzmq](http://github.com/moteus/lzmq)

###writer.net.smtp###
* [LuaSocket](http://www.impa.br/~diego/software/luasocket)
* [lua-sendmail](http://github.com/moteus/lua-sendmail)

***

## Usage ##

Write to file from separate thread.

```lua
local LOG = require "log".new(
  require "log.writer.async.zmq".new(
    'inproc://async.logger',
    "return require 'log.writer.file.by_day'.new('./logs', 'events.log', 5000)"
  )
)

LOG.error("some error")
```

More complex example
```lua
local host = arg[1] or '127.0.0.1'
local port = arg[2] or 514

-- this code run in separate thread.
local InitWriter = [[
  return require 'log.writer.list'.new(                  -- multi writers:
    require 'log.writer.console.color'.new(),            -- * console color
    require 'log.writer.net.zmq'.new('%{zmq_cnn_host}'), -- * zmq pub socket
    require "log.writer.format".new(                     -- * syslog over udp
      require "log.logformat.syslog".new("user"),
      require 'log.writer.net.udp'.new('%{udp_cnn_host}', %{udp_cnn_port})
    )
  )
]]

-- create async writer and run new work thread.
-- communicate with work thread using zmq library
local writer = require "log.writer.async.zmq".new(
  'inproc://async.logger', 
  InitWriter:gsub('%%{(.-)}', {
    zmq_cnn_host = 'tcp://' .. host .. ':' .. port;
    udp_cnn_host = host;
    udp_cnn_port = port;
  })
)

-- create new logger
local LOG = require"log".new(writer)

require "socket".sleep(0.5) -- net.zmq need time to connect

LOG.fatal("can not allocate memory")
LOG.error("file not found")
LOG.warning("cache server is not started")
LOG.info("new message is received")
LOG.notice("message has 2 file")

print("Press enter ...") io.flush() io.read()
```
