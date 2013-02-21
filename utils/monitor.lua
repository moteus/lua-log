local function write(who, msg) print(who .. ' : ' ..  msg) end
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
if uskt.getfd then assert(uskt:setsockname(udp_bind_host, udp_bind_port))
else 
  print("UDP do not support!")
  uskt:close()
  uskt = nil
end

local ctx = zmq.init(1)
local zskt = ctx:socket(zmq.SUB)
zassert((zskt.set_subscribe or zskt.subscribe)(zskt, ''))
zassert(zskt:bind(zmq_bind_host))

local loop = zpoller.new(2)

loop:add(zskt, zmq.POLLIN, function()
  local msg = zrecv_all(zskt)
  if msg[2] then write(tostring(msg[1]), tostring(msg[2]))
  else write('zmq://unknown', tostring(msg[1])) end
end)

if uskt then
  loop:add(uskt:getfd(), zmq.POLLIN, function()
    local msg, ip, port = uskt:receivefrom()
    local name = 'udp://' .. ip .. ":" .. port
    write(name, msg)
  end)
end

loop:start()
