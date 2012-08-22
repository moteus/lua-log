local Log = require"log"
local cio = require"cio"

local function color_writeln(attr, text)
  cio.textattr(attr)
  cio.writeln(text)
end

local colors = {
  [Log.LVL.FOTAL   ] = 'n/r+';
  [Log.LVL.ERROR   ] = 'r+/n';
  [Log.LVL.WARNING ] = 'm+/n';
  [Log.LVL.INFO    ] = 'w+/n';
  [Log.LVL.NOTICE  ] = 'c+/n';
  [Log.LVL.DEBUG   ] = 'y+/n';
}

local function console_writer(msg, lvl)
  color_writeln(colors[lvl], msg)
end

local M = {}

function M.new() return console_writer end

return M