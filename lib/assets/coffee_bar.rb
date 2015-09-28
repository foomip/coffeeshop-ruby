require 'concurrent-edge'

require 'dataset'
require 'utils/print_message'

module Assets
  class CoffeeBar < Concurrent::Actor::RestartingContext
    include PrintMessage

    attr_reader :places, :coffee_machine, :baristas, :customers
    attr_reader :waiting_for_service, :msg_colour, :msg_bgcolour
    attr_reader :identifier

    def self.build_coffee_bar coffee_machine, baristas
      places = Dataset.get.coffee_bar_places

      CoffeeBar.spawn :coffee_bar, places, coffee_machine, baristas
    end

    def initialize places, coffee_machine, baristas
      @places               = places
      @coffee_machine       = coffee_machine
      @baristas             = baristas
      @customers            = []
      @waiting_for_service  = []
      @msg_colour           = :light_cyan
      @msg_bgcolour         = nil
      @identifier           = 'Coffee Bar'
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :sit_down
        customer = message

        if customers.length == places
          false
        else
          customers << customer
          waiting_for_service << customer
          true
        end
      when :full
        customers.length == places
      else
        log "WARNING: Coffee bar received message of type #{msg_type}: #{message} - don't know what to do??"
      end
    end
  end
end
