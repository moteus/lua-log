local file = require "log.writer.file"

function M.new(log_dir, log_name, roll_count, max_size)
  return file.new{
    log_dir    = log_dir, 
    log_name   = log_name,
    max_size   = max_size,
    roll_count = assert(roll_count),
    close_file = false,
  }
end

return M

