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
