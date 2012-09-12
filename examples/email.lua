local writer = require "log.writer.net.smtp".new(
  'program@some.mail', 'alex@some.mail', '127.0.0.1', 'test logger'
)
local LOG = require "log".new(writer)
LOG.fotal('test message')
