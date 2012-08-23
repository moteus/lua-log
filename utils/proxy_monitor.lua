local zmq      = require"lzmq"
local zloop    = require"lzmq.loop"
local socket   = require"socket"
local cmsgpack = require"cmsgpack.safe"

local ok, console = pcall(require, "log.writer.console.color")
if not ok then console = require "log.writer.console" end

local writer = console.new()

local function write(msg)
  local msg, lvl, now = cmsgpack.unpack(msg)
  now = date(now)
  writer(msg, lvl, now)
end

local host = arg[1] or '127.0.0.1'
local port = arg[2] or 514

local zmq_bind_host = 'tcp://' .. host .. ':' .. port
local udp_bind_host = host
local udp_bind_port = port

local loop = zloop.new(2)

local zskt = loop:add_new_bind(zmq.PULL, zmq_bind_host, function(skt) 
  local msg = skt:recv_all()
  write(msg[1])
end)

local uskt = assert(socket.udp())
assert(uskt:setsockname(udp_bind_host, udp_bind_port))
loop:add_socket(uskt:getfd(), function() 
  local msg = uskt:receivefrom()
  write( msg  )
end)


loop:start()
