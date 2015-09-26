module PrintMessage
  def log msg
    x = '[ '.colorize(color: msg_colour, background: msg_bgcolour)
    y = identifier.colorize(color: :white, background: msg_bgcolour, mode: :underline)
    z = " ] - #{msg}".colorize(color: msg_colour, background: msg_bgcolour)

    puts "#{x}#{y}#{z}"
  end
end
