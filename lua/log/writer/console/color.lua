local Log = require"log"

local make_attr, color_writeln, COLORS

if not COLORS then -- afx cio
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
end

if not COLORS then -- conio
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

if not COLORS then -- ansicolors
  local IS_WINDOWS = (package.config:sub(1,1) == '\\')
  local ok, c
  if not IS_WINDOWS then ok, c = pcall(require, "ansicolors") end
  if ok then
    COLORS = {
      BLACK        = 1;
      BLUE         = 2;
      GREEN        = 3;
      CYAN         = 4;
      RED          = 5;
      MAGENTA      = 6;
      BROWN        = 7;
      LIGHTGRAY    = 8;
      DARKGRAY     = 9;
      LIGHTBLUE    = 10;
      LIGHTGREEN   = 11;
      LIGHTCYAN    = 12;
      LIGHTRED     = 13;
      LIGHTMAGENTA = 14;
      YELLOW       = 15;
      WHITE        = 16;
    }
    local reset = tostring(c.reset)
    local fore = {
      [ COLORS.BLACK        ] = c.black  ;
      [ COLORS.BLUE         ] = c.blue   ;
      [ COLORS.GREEN        ] = c.green  ;
      [ COLORS.CYAN         ] = c.cyan   ;
      [ COLORS.RED          ] = c.red    ;
      [ COLORS.MAGENTA      ] = c.magenta;
      [ COLORS.BROWN        ] = c.yellow ;
      [ COLORS.LIGHTGRAY    ] = c.white  ;
      [ COLORS.DARKGRAY     ] = c.black   .. c.bright;
      [ COLORS.LIGHTBLUE    ] = c.blue    .. c.bright;
      [ COLORS.LIGHTGREEN   ] = c.green   .. c.bright;
      [ COLORS.LIGHTCYAN    ] = c.cyan    .. c.bright;
      [ COLORS.LIGHTRED     ] = c.red     .. c.bright;
      [ COLORS.LIGHTMAGENTA ] = c.magenta .. c.bright;
      [ COLORS.YELLOW       ] = c.yellow  .. c.bright;
      [ COLORS.WHITE        ] = c.white   .. c.bright;
    }

    local back = {
      [ COLORS.BLACK        ] = c.onblack  ;
      [ COLORS.BLUE         ] = c.onblue   ;
      [ COLORS.GREEN        ] = c.ongreen  ;
      [ COLORS.CYAN         ] = c.oncyan   ;
      [ COLORS.RED          ] = c.onred    ;
      [ COLORS.MAGENTA      ] = c.onmagenta;
      [ COLORS.BROWN        ] = c.onyellow ;
      [ COLORS.LIGHTGRAY    ] = c.onwhite  ;
      [ COLORS.DARKGRAY     ] = c.onblack   .. c.bright;
      [ COLORS.LIGHTBLUE    ] = c.onblue    .. c.bright;
      [ COLORS.LIGHTGREEN   ] = c.ongreen   .. c.bright;
      [ COLORS.LIGHTCYAN    ] = c.oncyan    .. c.bright;
      [ COLORS.LIGHTRED     ] = c.onred     .. c.bright;
      [ COLORS.LIGHTMAGENTA ] = c.onmagenta .. c.bright;
      [ COLORS.YELLOW       ] = c.onyellow  .. c.bright;
      [ COLORS.WHITE        ] = c.onwhite   .. c.bright;
    }

    make_attr = function (F, B) return fore[F] .. back[B] end
    color_writeln = function (attr, text) io.write(attr, text, reset, '\n') end
  end
end

if not COLORS then -- fallback to console
  return require"log.writer.console"
end

local colors = {
  [Log.LVL.EMERG     ] = make_attr(COLORS.WHITE,        COLORS.LIGHTRED); 
  [Log.LVL.ALERT     ] = make_attr(COLORS.BLUE,         COLORS.LIGHTRED); 
  [Log.LVL.FATAL     ] = make_attr(COLORS.BLACK,        COLORS.LIGHTRED);
  [Log.LVL.ERROR     ] = make_attr(COLORS.LIGHTRED,     COLORS.BLACK);
  [Log.LVL.WARNING   ] = make_attr(COLORS.LIGHTMAGENTA, COLORS.BLACK);
  [Log.LVL.NOTICE    ] = make_attr(COLORS.LIGHTCYAN,    COLORS.BLACK);
  [Log.LVL.INFO      ] = make_attr(COLORS.WHITE,        COLORS.BLACK);
  [Log.LVL.DEBUG     ] = make_attr(COLORS.YELLOW,       COLORS.BLACK);
  [Log.LVL.TRACE     ] = make_attr(COLORS.LIGHTGREEN,   COLORS.BLACK);
}

local function console_writer(fmt, msg, lvl, now)
  color_writeln(colors[lvl], fmt(msg, lvl, now))
end

local M = {}

function M.new() return console_writer end

return M
