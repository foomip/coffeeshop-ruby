require 'colorize'

LOG_LEVEL = Struct.new(:debug, :info, :warn, :error).new(
  'DEBUG', 'INFO', 'WARN', 'ERROR'
)

def message_printer_setup identifier, colour
  ->(msg, level=LOG_LEVEL.info) {
    x = '[ '.colorize(color: colour)
    y = identifier.colorize(color: :white, mode: :underline)
    z = " ] #{level} - #{msg}".colorize(color: colour)

    puts "#{x}#{y}#{z}"
  }
end
