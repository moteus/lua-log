local LogLib = require"log"
local Format = require "log.writer.format"
local SysLog = require "log.logformat.syslog"

local writer = require "log.writer.list".new(
  Format.new( -- explicit set logformat to console
    require "log.logformat.default".new(), 
    require "log.writer.stdout".new()
  ),
  require "log.writer.net.udp".new('127.0.0.1', 514)
)

local LOG_FMT = LogLib.new('trace', writer,
  require "log.formatter.format".new(),
  SysLog.new('kern')
)

local LOG_CON = LogLib.new('trace', writer,
  require "log.formatter.concat".new(),
  SysLog.new('USER')
)

local LOG     = LogLib.new('trace', writer, nil, SysLog.new('USER'))

LOG.emerg       ('!! EMERG   !!')
LOG_FMT.alert   ('!! %-7s !!', 'ALERT'   )
LOG_FMT.fatal   ('!! %-7s !!', 'FATAL'   )
LOG_FMT.error   ('!! %-7s !!', 'ERROR'   )
LOG_CON.warning ('!!', 'WARNING', '!!')
LOG_FMT.notice  ('!! %-7s !!', 'NOTICE'  )
LOG_FMT.info    ('!! %-7s !!', 'INFO'    )
LOG_FMT.debug   ('!! %-7s !!', 'DEBUG'   )
LOG_FMT.trace   ('!! %-7s !!', 'TRACE'   )
