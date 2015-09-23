require 'concurrent-edge'
require 'active_support/inflector'

require 'utils/print_message'

module People
  class MaitreD < Concurrent::Actor::RestartingContext
    include PrintMessage

    attr_reader :tables, :msg_colour, :msg_bgcolour, :identifier

    def self.hire_maitre_d tables
      MaitreD.spawn :maitre_d, tables
    end

    def initialize tables
      @tables = tables
      @identifier = "Maire'D"
      @msg_colour = :blue
      @msg_bgcolour = :white
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :customer_arrived
        seat_customer message
      when :coffeeshop_empty
        false
      else
        log "WARNING: Maitre D received message of type #{msg_type}: #{message} - don't know what to do??"
      end
    end

    def seat_customer data
      seat_at, customers = data

      if seat_at == :table
        log "Seating #{customers.length} #{'customer'.pluralize customers.length} at table ?"
      else
        log "Directing customer to coffee bar"
      end
    end
  end
end
