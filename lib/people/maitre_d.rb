require 'concurrent-edge'
require 'active_support/inflector'

require 'dataset'
require 'utils/print_message'
require 'people/customer'

module People
  class MaitreD < Concurrent::Actor::RestartingContext
    include PrintMessage

    attr_reader :tables, :msg_colour, :msg_bgcolour, :identifier, :customers
    attr_reader :seating_variance, :coffee_bar

    def self.hire_maitre_d tables, coffee_bar
      MaitreD.spawn :maitre_d, tables, coffee_bar, Dataset.get.seating_variance
    end

    def initialize tables, coffee_bar, seating_variance
      @tables             = tables
      @coffee_bar         = coffee_bar
      @seating_variance   = seating_variance
      @identifier         = "Maitre'D"
      @msg_colour         = :light_blue
      @msg_bgcolour       = :default
      @customers          = []
      @customers_waiting  = []
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :customer_arrived
        seat_customer message
      when :coffee_bar_full
        customers = [message]
        assign_table_to customers
      when :coffeeshop_empty
        false
      else
        log "WARNING: Maitre D received message of type #{msg_type}: #{message} - don't know what to do??"
      end
    end

    def seat_customer data
      cust_data, arrival_time = data
      seat_at, customers      = cust_data

      if seat_at == :table
        seat_customers customers, arrival_time
      else
        send_to_coffee_bar customers, arrival_time
      end
    end

    def seat_customers data, arrival_time
      customers = Customer.welcome_customers data, self, arrival_time

      assign_table_to customers
    end

    def assign_table_to customers
      # simulate variable time taken to get customers seated
      sleep seating_variance.sample

      total     = customers.length

      table = tables.select do |t|
        !t.occupied? && t.places >= total

      end.sort do |left, right|
        (left.places - total) <=> (right.places - total)
      end.first

      if table
        log "Seating #{customers.length} #{'customer'.pluralize customers.length} at table #{table.id} (table has #{table.places} #{'place'.pluralize table.places})"
        table.seat customers
        table.tell_waiter [:customers_seated, table.id]
        @customers + customers
      else
        puts "MAITRE'D - TODO: handle case where no tables are available for customers".red
      end
    end

    def send_to_coffee_bar data, arrival_time
      customer = Customer.welcome_customers(data, self, arrival_time).first

      customer.tell [:find_a_seat, [coffee_bar, self]]
    end
  end
end
