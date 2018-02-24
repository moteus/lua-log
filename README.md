# Asynchronous logging library for Lua

## Usage

### Write to file from separate thread.

This example shows how to start file writer in separate thread.

```lua
local LOG = require "log".new(
  require "log.writer.async.zmq".new(
    'inproc://async.logger',
    function() -- calls from separate thread/Lua state
      return require 'log.writer.file.by_day'.new(
        './logs', 'events.log', 5000
      )
    end
  )
)

LOG.error("some error")
```

### Sendout logs to separate process/host

This example show how to send logs in 2 separate destination
with 2 formats. Write to stdout as whell as to remote syslog
server. In fact here no async on Lua side. Application write
to network directly from main thread. But it is possible use
one or more work threads that will do this.

```Lua
-- Buld writer with 2 destinations
local writer = require "log.writer.list".new(
  require "log.writer.format".new(
    -- explicit set logformat to stdout writer
    require "log.logformat.default".new(), 
    require "log.writer.stdout".new()
  ),
  -- define network writer.
  -- This writer has no explicit format so it will
  -- use one defined for logger.
  require "log.writer.net.udp".new('127.0.0.1', 514)
)

local function SYSLOG_NEW(level, ...)
  return require "log".new(level, writer,
    require "log.formatter.mix".new(),
    require "log.logformat.syslog".new(...)
  )
end

local SYSLOG = {
  -- Define first syslog logger with some settings
  KERN = SYSLOG_NEW('trace', 'kern'),
  
  -- Define second syslog logger with other settings
  USER = SYSLOG_NEW('trace', 'USER'),
}

SYSLOG.KERN.emerg ('emergency message')
SYSLOG.USER.alert ('alert message')
```


***

## Dependences

### core
* LuaDate

### writer.async.udp
* [llthreads](http://github.com/Neopallium/lua-llthreads)
* writer.net.udp

### writer.async.zmq
* [llthreads](http://github.com/Neopallium/lua-llthreads)
* writer.net.zmq

### writer.console.color
* ansicolors
* or lua-conio
* or cio (Windows only)

### writer.file.by_day
* [lfs](http://keplerproject.github.com/luafilesystem)

### writer.net.udp
* [LuaSocket](http://www.impa.br/~diego/software/luasocket)

### writer.net.zmq
* [lua-zmq](http://github.com/Neopallium/lua-zmq)
* or [lzmq](http://github.com/moteus/lzmq)

### writer.net.smtp
* [LuaSocket](http://www.impa.br/~diego/software/luasocket)
* [lua-sendmail](http://github.com/moteus/lua-sendmail)

