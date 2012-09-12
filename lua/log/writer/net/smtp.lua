local Log      = require "log"
local sendmail = require "sendmail"

local M = {}

function M.new(from, to, server, subject)
  assert(to,     "'to' parameter is required")
  assert(from,   "'from' parameter is required")
  assert(server, "'server' parameter is required")

  subject = subject or ''

  return function(msg, lvl, now)
    sendmail(from, to, server, {
      subject = now:fmt("%F %T") .. ' [' .. Log.LVL_NAMES[lvl] .. '] ' .. subject;
      text    = msg;
    })
  end
end

return M