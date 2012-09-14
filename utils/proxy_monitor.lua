local log_packer = require"log.logformat.proxy.pack"
local writer = require"log.writer.format".new(
  require"log.logformat.default".new(),
  require"log.writer.console.color".new()
)

local function write(msg)
  local msg, lvl, now = log_packer.unpack(msg)
  if msg and lvl and now then writer(nil, msg, lvl, now) end
end
-----------------------------------------------------------------------

local socket = require"socket"
local ok, zmq, zpoller = pcall(require, "lzmq")
if ok then zpoller  = require"lzmq.poller"
else
  zmq      = require"zmq"
  zpoller  = require"zmq.poller"
end
local zassert = zmq.assert or assert

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
end

local ctx = zmq.init(1)
local zskt = ctx:socket(zmq.PULL)
zassert(zskt:bind(zmq_bind_host))
local zrecv_all
if zskt.recv_all then
  zrecv_all = zskt.recv_all 
else
  zrecv_all = function(skt)
    local t = {}
    local r, err = skt:recv()
    if not r then return nil, err end
    table.insert(t,r)
    while skt:rcvmore() == 1 do
      r, err = skt:recv()
      if not r then return nil, err, t end
      table.insert(t,r)
    end 
    return t
  end
end

local loop = zpoller.new(2)

loop:add(zskt, zmq.POLLIN, function()
  local msg = zrecv_all(zskt)
  write(msg[1])
end)

if uskt then
  loop:add(uskt:getfd(), zmq.POLLIN, function()
    local msg, ip, port = uskt:receivefrom()
    write(msg)
  end)
end

loop:start()
