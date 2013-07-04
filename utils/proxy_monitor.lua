local log_packer = require "log.logformat.proxy.pack"
local logformat  = require "log.logformat.default".new()
local writer     = require "log.writer.console.color".new()
local function write(msg)
  local msg, lvl, now = log_packer.unpack(msg)
  if msg and lvl and now then writer(logformat, msg, lvl, now) end
end
-----------------------------------------------------------------------

local socket = require "socket"
local Z      = require "log.writer.net.zmq._private.compat"
local zmq, zpoller = Z.zmq, Z.poller
local zassert, zrecv_all = Z.assert, Z.recv_all

local host = arg[1] or '127.0.0.1'
local port = arg[2] or 514

local zmq_bind_host = 'tcp://' .. host .. ':' .. port
local udp_bind_host = host
local udp_bind_port = port

local uskt = assert(socket.udp())
assert(uskt:setsockname(udp_bind_host, udp_bind_port))

local ctx = zmq.init(1)
local zskt = ctx:socket(zmq.PULL)
zassert(zskt:bind(zmq_bind_host))

local loop = zpoller.new(2)

loop:add(zskt, zmq.POLLIN, function()
  local msg = zrecv_all(zskt)
  write(msg[1])
end)

loop:add(uskt:getfd(), zmq.POLLIN, function()
  local msg, ip, port = uskt:receivefrom()
  write(msg)
end)

loop:start()
