require 'concurrent-edge'

require 'dataset'
require 'utils/message_printer'

module Assets
  class CoffeeBar < Concurrent::Actor::RestartingContext
    attr_reader :logger, :places, :customers

    def self.build_coffee_bar coffee_machines, baristas
      logger = message_printer_setup 'Cofee bar', Dataset.get.colours.coffee_bar
      places = Dataset.get.total.coffee_bar_places

      CoffeeBar.spawn :coffee_bar, logger, places
    end

    def initialize logger, places
      @logger     = logger
      @places     = places
      @customers  = []
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :give_me_a_seat
        if customers.length == places
          false
        else
          self.customers << message
          true
        end
      when :has_places_available
        places > self.customers.length
      else
        logger.call "Received message of type #{msg_type}: #{message} - don't know what to do??", LOG_LEVEL.warn
        return
      end
    end
  end
end
