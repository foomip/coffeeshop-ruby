require 'colorize'

require 'dataset'

LOG_LEVEL = Struct.new(:debug, :info, :warn, :error).new(
  'DEBUG', 'INFO', 'WARN', 'ERROR'
)

CURRENT_LOG_LEVEL = Dataset.get.log_level

def message_printer_setup identifier, colour
  ->(msg, level=LOG_LEVEL.info) {
    show_log = case CURRENT_LOG_LEVEL
    when LOG_LEVEL.error
      level = LOG_LEVEL.error
    when LOG_LEVEL.warn
      [LOG_LEVEL.error, LOG_LEVEL.warn].include? level
    when LOG_LEVEL.info
      [LOG_LEVEL.error, LOG_LEVEL.warn, LOG_LEVEL.info].include? level
    when LOG_LEVEL.debug
      [LOG_LEVEL.error, LOG_LEVEL.warn, LOG_LEVEL.info, LOG_LEVEL.debug].include? level
    else
      false
    end

    if show_log
      x = '[ '.colorize(color: colour)
      y = identifier.colorize(color: :white, mode: :underline)
      z = " ] #{level} - #{msg}".colorize(color: colour)

      puts "#{x}#{y}#{z}"
    end
  }
end
