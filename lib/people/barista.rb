require 'concurrent-edge'

require 'dataset'
require 'utils/message_printer'

module People
  class Barista < Concurrent::Actor::RestartingContext
    attr_reader :logger, :coffee_machines, :coffee_bar

    def self.hire_baristas coffee_machines
      msg_colour = Dataset.get.colours.barista

      Dataset.get.total.baristas.times.map do |i|
        logger = message_printer_setup "Barista #{i}", msg_colour

        Barista.spawn "Barista #{i}", logger, coffee_machines
      end
    end

    def initialize logger, coffee_machines
      @logger           = logger
      @coffee_machines  = coffee_machines
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :coffee_bar_readyzzz
        @coffee_bar = message
      else
        logger.call "Received message of type #{msg_type}: #{message} - don't know what to do??", LOG_LEVEL.warn
      end
    end
  end
end
