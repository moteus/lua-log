local date    = require "date"
local schar   = string.char
local sbyte   = string.byte
local sformat = string.format
local ssub    = string.sub
local tn      = tonumber

local M = {}

function M.pack(msg, lvl, now)
  local Y, M, D = now:getdate()
  local h, m, s = now:gettime()
  local now_s = sformat("%.4d-%.2d-%2d %.2d:%.2d:%2d", Y, M, D, h, m, s)

  return schar(lvl) .. now_s .. msg
end

function M.unpack(str)
  local now_s = ssub(str, 2, 20 )
  local Y, M, D = ssub(str, 2, 5 ), ssub(str, 7, 8 ), ssub(str, 10, 11 )
  local h, m, s = ssub(str, 13, 14 ), ssub(str, 16, 17 ), ssub(str, 19, 20 )

  return ssub(str, 21), sbyte( ssub(str, 1, 1) ), date(tn(Y), tn(M), tn(D), tn(h), tn(m), tn(s))
end

return M