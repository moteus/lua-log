package = "lua-log"
version = "0.1.4-1"
source = {
  url = "https://github.com/moteus/lua-log/archive/v0.1.4.zip",
  dir = "lua-log-0.1.4",
}

description = {
  summary = "Asynchronous logging library",
  detailed = [[
  ]],
  homepage = "https://github.com/moteus/lua-log",
  license  = "MIT/X11",
}

dependencies = {
  "lua >= 5.1",
  "date >= 2.0",
  -- "llthread >= 1.2",
  -- "luasocket >= 2.0.1",
  -- "lzmq >= 0.1.0",
  -- "sendmail >= 0.1.0",
  -- "lanes >= 3.5",
  -- "ansicolors >= 1.0",
}

build = {
  type = "builtin",
  copy_directories = {
    "examples",
    "utils",
    "doc",
  },
  modules = {
    ["log"                         ] = "lua/log.lua",
    ["log.formatter.concat"        ] = "lua/log/formatter/concat.lua",
    ["log.formatter.format"        ] = "lua/log/formatter/format.lua",
    ["log.formatter.mix"           ] = "lua/log/formatter/mix.lua",
    ["log.logformat.default"       ] = "lua/log/logformat/default.lua",
    ["log.logformat.proxy"         ] = "lua/log/logformat/proxy.lua",
    ["log.logformat.proxy.pack"    ] = "lua/log/logformat/proxy/pack.lua",
    ["log.logformat.syslog"        ] = "lua/log/logformat/syslog.lua",
    ["log.writer.async._private.server"    ] = "lua/log/writer/async/_private/server.lua",
    ["log.writer.async.lane"       ] = "lua/log/writer/async/lane.lua",
    ["log.writer.async.server.lane"] = "lua/log/writer/async/server/lane.lua",
    ["log.writer.async.server.udp" ] = "lua/log/writer/async/server/udp.lua",
    ["log.writer.async.server.zmq" ] = "lua/log/writer/async/server/zmq.lua",
    ["log.writer.async.udp"        ] = "lua/log/writer/async/udp.lua",
    ["log.writer.async.zmq"        ] = "lua/log/writer/async/zmq.lua",
    ["log.writer.console"          ] = "lua/log/writer/console.lua",
    ["log.writer.console.color"    ] = "lua/log/writer/console/color.lua",
    ["log.writer.file"             ] = "lua/log/writer/file.lua",
    ["log.writer.file.by_day"      ] = "lua/log/writer/file/by_day.lua",
    ["log.writer.file.private.impl"] = "lua/log/writer/file/private/impl.lua",
    ["log.writer.file.roll"        ] = "lua/log/writer/file/roll.lua",
    ["log.writer.filter"           ] = "lua/log/writer/filter.lua",
    ["log.writer.filter.lvl.eq"    ] = "lua/log/writer/filter/lvl/eq.lua",
    ["log.writer.filter.lvl.le"    ] = "lua/log/writer/filter/lvl/le.lua",
    ["log.writer.format"           ] = "lua/log/writer/format.lua",
    ["log.writer.list"             ] = "lua/log/writer/list.lua",
    ["log.writer.net.server.udp"   ] = "lua/log/writer/net/server/udp.lua",
    ["log.writer.net.server.zmq"   ] = "lua/log/writer/net/server/zmq.lua",
    ["log.writer.net.smtp"         ] = "lua/log/writer/net/smtp.lua",
    ["log.writer.net.udp"          ] = "lua/log/writer/net/udp.lua",
    ["log.writer.net.zmq"          ] = "lua/log/writer/net/zmq.lua",
    ["log.writer.net.zmq._private.compat"  ] = "lua/log/writer/net/zmq/_private/compat.lua",
    ["log.writer.net.zmq._private.impl"    ] = "lua/log/writer/net/zmq/_private/impl.lua",
    ["log.writer.net.zmq.pub"      ] = "lua/log/writer/net/zmq/pub.lua",
    ["log.writer.net.zmq.push"     ] = "lua/log/writer/net/zmq/push.lua",
    ["log.writer.net.zmq.srv.pub"  ] = "lua/log/writer/net/zmq/srv/pub.lua",
    ["log.writer.stderr"           ] = "lua/log/writer/stderr.lua",
    ["log.writer.stdout"           ] = "lua/log/writer/stdout.lua",
  }
}



