local zmq    = require"lzmq"
local zloop  = require"lzmq.loop"
local socket = require"socket"


local host = arg[1] or '127.0.0.1'
local port = arg[2] or 514

local zmq_bind_host = 'tcp://' .. host .. ':' .. port
local udp_bind_host = host
local udp_bind_port = port


local function write(who, msg)
  print(who .. ' : ' ..  msg)
end


local loop = zloop.new(2)

local zskt = loop:add_new_bind(zmq.SUB, zmq_bind_host, function(skt) 
  local msg = skt:recv_all()
  write(msg[1], msg[2])
end)
zskt:set_subscribe('')

local uskt = assert(socket.udp())
assert(uskt:setsockname(udp_bind_host, udp_bind_port))
loop:add_socket(uskt:getfd(), function() 
  local msg, ip, port = uskt:receivefrom()
  local name = 'udp://' .. ip .. ":" .. port
  write(name, msg)
end)


loop:start()
