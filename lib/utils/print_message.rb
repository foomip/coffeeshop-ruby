module PrintMessage
  def log msg
    puts "[#{identifier}] #{msg}".colorize(color: msg_colour, background: msg_bgcolour)
  end
end
