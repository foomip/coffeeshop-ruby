require 'concurrent-edge'

require 'dataset'
require 'utils/message_printer'

module Assets
  class CoffeeBar < Concurrent::Actor::RestartingContext
    attr_reader :logger, :places, :customers, :waiting_orders, :coffee_machines

    def self.build_coffee_bar coffee_machines
      logger = message_printer_setup 'Cofee bar', Dataset.get.colours.coffee_bar
      places = Dataset.get.total.coffee_bar_places

      CoffeeBar.spawn :coffee_bar, logger, places, coffee_machines
    end

    def initialize logger, places, coffee_machines
      @logger           = logger
      @places           = places
      @coffee_machines  = coffee_machines
      @customers        = []
      @waiting_orders   = []
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :give_me_a_seat
        if self.customers.length == places
          false
        else
          self.customers << message
          true
        end
      when :has_places_available
        places > self.customers.length
      when :place_table_order
        orders, table, waiter = message
        self.waiting_orders << order_struct.new(orders, table, waiter)
        return
      when :get_table_order
        self.waiting_orders.shift
      when :get_customers
        self.customers
      when :customer_leaving
        customer = message
        self.customers.delete customer
        return
      when :get_places
        self.places
      else
        logger.call "Received message of type #{msg_type}: #{message} - don't know what to do??", LOG_LEVEL.warn
        return
      end
    end

    def order_struct
      @order_struct ||= Struct.new :orders, :table, :waiter
    end
  end
end
