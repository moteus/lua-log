local Log = require"log"

local make_attr, color_writeln, COLORS

local ok, cio = pcall(require, "cio")
if ok then
  COLORS = {
    BLACK        = 'n';
    BLUE         = 'b';
    GREEN        = 'g';
    CYAN         = 'c';
    RED          = 'r';
    MAGENTA      = 'm';
    BROWN        = 'y';
    LIGHTGRAY    = 'w';
    DARKGRAY     = 'n+';
    LIGHTBLUE    = 'b+';
    LIGHTGREEN   = 'g+';
    LIGHTCYAN    = 'c+';
    LIGHTRED     = 'r+';
    LIGHTMAGENTA = 'm+';
    YELLOW       = 'y+';
    WHITE        = 'w+';
  }
  make_attr = function (F, B) return F .. '/' .. B end
  color_writeln = function (attr, text)
    cio.textattr(attr)
    cio.writeln(text or "")
  end
end

if not ok then
  local ok, conio = pcall(require, "conio")
  if ok then
    COLORS = {
      BLACK        = conio.COLOR_BLACK        ;
      BLUE         = conio.COLOR_BLUE         ;
      GREEN        = conio.COLOR_GREEN        ;
      CYAN         = conio.COLOR_CYAN         ;
      RED          = conio.COLOR_RED          ;
      MAGENTA      = conio.COLOR_MAGENTA      ;
      BROWN        = conio.COLOR_BROWN        ;
      LIGHTGRAY    = conio.COLOR_LIGHTGRAY    ;
      DARKGRAY     = conio.COLOR_DARKGRAY     ;
      LIGHTBLUE    = conio.COLOR_LIGHTBLUE    ;
      LIGHTGREEN   = conio.COLOR_LIGHTGREEN   ;
      LIGHTCYAN    = conio.COLOR_LIGHTCYAN    ;
      LIGHTRED     = conio.COLOR_LIGHTRED     ;
      LIGHTMAGENTA = conio.COLOR_LIGHTMAGENTA ;
      YELLOW       = conio.COLOR_YELLOW       ;
      WHITE        = conio.COLOR_WHITE        ;
    }
    make_attr = function (F, B) return {F, B} end
    color_writeln = function (attr, text)
      conio.textcolor(attr[1])
      conio.textbackground(attr[2])
      conio.cputs((text or "") .. '\n')
    end
  else
    COLORS = {}
    make_attr = function(F, B) end
    color_writeln = function (attr, text) io.write(text, '\n') end
  end
end

local colors = {
  [Log.LVL.FOTAL   ] = make_attr(COLORS.BLACK,        COLORS.LIGHTRED);
  [Log.LVL.ERROR   ] = make_attr(COLORS.LIGHTRED,     COLORS.BLACK);
  [Log.LVL.WARNING ] = make_attr(COLORS.LIGHTMAGENTA, COLORS.BLACK);
  [Log.LVL.INFO    ] = make_attr(COLORS.WHITE,        COLORS.BLACK);
  [Log.LVL.NOTICE  ] = make_attr(COLORS.LIGHTCYAN,    COLORS.BLACK);
  [Log.LVL.DEBUG   ] = make_attr(COLORS.YELLOW,       COLORS.BLACK);
}

local function console_writer(msg, lvl)
  color_writeln(colors[lvl], msg)
end

local M = {}

function M.new() return console_writer end

return M
